 #!/bin/bash

##############################################################################
#
#  Hooty - a version of Patootie that uses agaetr's framework to send.
#  Using YAD and toot to have a GUI for sending a quick toot (with possible
#  images, content warnings, etc), also can send to Bluesky and Pixelfed 
#  (or really anything else that agaetr can send to). 
#  YAD = https://sourceforge.net/projects/yad-dialog/
#  toot = https://toot.bezdomni.net/
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

# If an argument is passed, it is assumed to be the image file to attach. 
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
Need_Image="FALSE"
IMAGE_FILE=""
ARCHIVEIS=0
IARCHIVE=0
LOUD=0
wget_bin=$(which wget)
python_bin=$(which python3)
declare -a services_array=()
declare -a on_array=()
services_string=""
pubtime=$(date +%D)
title=""
description=""
link=""
hashtags=""
cw=""
imgurl=""
Limgurl=""
ALT_TEXT=::


if [ -z "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
    export XDG_CONFIG_HOME="${HOME}/.config"
fi

if [ ! -d "${XDG_CONFIG_HOME}" ];then
    echo "Your XDG_CONFIG_HOME variable is not properly set and does not exist."
    exit 99
fi

if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "ERROR - INI NOT FOUND" >&2
    exit 99
else
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    if [ -f $(grep 'archiveis =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}') ];then 
        ARCHIVEIS=1
    fi
    if [ -f $(grep 'waybackpy =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}') ];then
        IARCHIVE=1
    fi
    if [ $IARCHIVE -eq 1 ] || [ $ARCHIVEIS -eq 1 ];then
        ArchiveLinks=$(grep 'ArchiveLinks =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    else
        ArchiveLinks=ignore
    fi    
fi

function loud() {
##############################################################################
# loud outputs on stderr 
##############################################################################    
    if [ $LOUD -eq 1 ];then
        echo "$@" 1>&2
    fi
}


display_help(){
##############################################################################
# Show the Help
##############################################################################    
    echo "###################################################################"
    echo "# Standalone: /path/to/hooty.sh [options]"
    echo "# Info ############################################################"
    echo "# --help - shows this"
    echo "# --media [FULL FILE PATH] - an image to pass"
    echo "# --link | --url"
    echo "# The following enable services"
    echo "# --toot"
    echo "# --bluesky"
    echo "# --pixelfed"    
    echo "###################################################################"
}

while [ $# -gt 0 ]; do
##############################################################################
# Get command-line parameters
##############################################################################

# You have to have the shift or else it will keep looping...
    option="$1"
    case $option in
        --loud)     export LOUD=1
                    shift
                    ;;
        --help)     display_help
                    exit
                    ;;
        --link|--url)      shift
                    link="${1}"
                    shift
                    ;;
        --media|--image)    shift
                    IMAGE_FILE="${1}"
                    Need_Image="TRUE"
                    shift
                    ;;
        --toot|--bluesky|--pixelfed)
                    # For service checks, see if they are in out/enabled, if not... then error?    
                    loud "Adding option ${1%:2}..."
                    on_array+=("${1:2}")
                    shift
                    ;;
        --locations) 
                    # I want to check if it's using the $HOME or flatpak ones here,
                    #check_for_config
                    echo "$XDG_CONFIG_HOME"
                    echo "$XDG_DATA_HOME"
                    exit
                    ;;
        *)          shift;;
    esac
done   

### NOTE ###
# Hooty uses *available*, not just *enabled* since it turns everything off by default.
posters=$(ls -A "$SCRIPT_DIR/out_avail") 
# Loop through files in the subdirectory (excluding .keep)
for file in $posters; do
    if [ "$file" != ".keep" ];then 
        if [[ " ${on_array[*]} " =~ [[:space:]]${file%.*}[[:space:]] ]]; then
            loud "${file%.*} activated by option"
            filename_no_ext=$(echo "${file%.*}")
            # Add to array
            services_array+=("$filename_no_ext")
            # Append to string (space-separated)
            services_string+="--field=$filename_no_ext:CHK TRUE "            
        fi            
        # It is not explicitly turned on by command line option
        if [[ ! " ${services_array[*]} " =~ [[:space:]]${file%.*}[[:space:]] ]]; then
            # whatever you want to do when array doesn't contain value
            loud "Adding option ${file%.*}..."
            filename_no_ext=$(echo "${file%.*}")
            # Add to array
            services_array+=("$filename_no_ext")
            # Append to string (space-separated)
            services_string+="--field=$filename_no_ext:CHK FALSE "
        fi
    fi
done
# Trim trailing space
services_string="${services_string% }"

 

ANSWER=$(yad --geometry=+400+200 --form --separator="±" --item-separator="," --on-top --title "patootie" --field="What to post?:TXT" "" --field="ContentWarning:CBE" none,discrimination,bigot,uspol,medicine,violence,reproduction,healthcare,LGBTQIA,climate,SocialMedia,other --field="url:TXT" "${link}" --field="Hashtags:TXT" "" -columns=2  --field="Attachment?":CHK "${Need_Image}"  ${services_string} --item-separator="," --button=Cancel:99 --button=Post:0)

# Make our services on/off array:
OIFS=$IFS
IFS='±' read -r -a temp_array <<< "${ANSWER}"
# Create a new array ignoring the first three entries (since they're not services)
services_on_array=("${temp_array[@]:5}")
IFS=$OIFS

# Get our text
TootText=$(echo "${ANSWER}" | awk -F '±' '{print $1}' | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/—/g' -e 's/)/—/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g')
if [ "${TootText}" == "" ];then
    echo "Nothing entered, exiting"
    exit 99
fi


# Get our Content Warning
cw=$(echo "${ANSWER}" | awk -F '±' '{print $2}' | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/—/g' -e 's/)/—/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g')
if [ "$cw" == "none" ];then 
    cw=""
fi

# Get our link
link=$(echo "${ANSWER}" | awk -F '±' '{print $3}' | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/—/g' -e 's/)/—/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g')
if [ "$link" == "none" ];then 
    link=""
else
    # Dealing with archiving links
    description2=""
    if [ $ARCHIVEIS -eq 1 ];then 
        source "$SCRIPT_DIR/archivers/archiveis.sh"
        loud "[info] Getting archive.is link"
        # this should now set ARCHIVEIS to the Archiveis url
        ARCHIVEIS=$(archiveis_send)
        # Making sure we get a URL back
        if [[ $ARCHIVEIS =~ http* ]];then
            loud "[info] Got archive.is link of ${ARCHIVEIS} "
            description2=" ais: ${ARCHIVEIS}"
            description2_md=" [ais](${ARCHIVEIS})"
            description2_html=" <a href=\"${ARCHIVEIS}\">ais</a>"
        else
            loud "[error] Did not get archive.is link"
        fi
    fi

    if [ $IARCHIVE -eq 1 ];then
        loud "[info] Getting Wayback link (this may take literally 1-3 minutes!)"
        source "$SCRIPT_DIR/archivers/wayback.sh"
        # this should now set IARCHIVE to the IARCHIVE url
        IARCHIVE=$(wayback_send)
        # I may need to put in a shortening thing here
        # Making sure we get a URL back
        echo "$IARCHIVE"
        if [[ $IARCHIVE =~ http* ]];then
            loud "[info] Got Wayback link of ${IARCHIVE} "
            # They are always SUPER long
            if [ $SHORTEN -eq 1 ];then
                loud "[info] Shortening wayback"
                shortlink=$(yourls_shortener "${IARCHIVE}")
                if [[ $shortlink =~ http* ]];then
                    loud "[info] Wayback shortened to ${shortlink}"
                    IARCHIVE="${shortlink}"
                fi
            fi
            description2="${description2} ia: ${IARCHIVE} "
            description2_md="${description2_md}  [ia](${IARCHIVE})"
            description2_html="${description2_html} <a href=\"${IARCHIVE}\">ia</a>"
        else
            loud "[error] Did not get Wayback link"
        fi
    fi
fi

# Get our hashtags
hashtags=$(echo "${ANSWER}" | awk -F '±' '{print $4}' | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/—/g' -e 's/)/—/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g')
if [ "$hashtags" == "none" ];then 
    hashtags=""
fi


if [ "$IMAGE_FILE" == "" ];then  # if there wasn't one by command line
    # to see if need to select image
    Need_Image=$(echo "$ANSWER" | awk -F '±' '{print $4}')
fi

if [ "${Need_Image}" == "TRUE" ];then 
    if [ "${IMAGE_FILE}" == "" ]; then # if there wasn't one by command line
        IMAGE_FILE=$(yad --geometry=+200+200  --on-top --title "Select image to add" --width=500 --height=400 --file --file-filter "Graphic files | *.jpg *.png *.webp *.jpeg")
    fi
    if [ ! -f "${IMAGE_FILE}" ];then
        SendImage=""
    else
        # resizing for socials will be handled by out modules.
        filename=$(basename -- "$IMAGE_FILE")
        extension="${filename##*.}"
        SendImage=$(mktemp --suffix=.${extension})
        TempImage=$(mktemp --suffix=.${extension})
        cp "${IMAGE_FILE}" "${SendImage}"
        # resizing for alt text
        if [ -f /usr/bin/convert ];then
            /usr/bin/convert -resize 800x512\! "${SendImage}" "${TempImage}" 
        else
            cp "${IMAGE_FILE}" "${TempImage}"
        fi
        ALT_TEXT=$(yad --geometry=+200+200 --window-icon=musique --on-top --skip-taskbar --image-on-top --borders=5 --title "Choose your alt text" --image "${TempImage}" --form --separator="" --item-separator="," --text-align=center --field="Alt text to use?:TXT" "I was too lazy to put alt text" --item-separator="," --separator="")
        if [ -f "${TempImage}" ];then
            rm "${TempImage}"
        fi
        if [ ! -z "$ALT_TEXT" ];then 
            # parens changed here because otherwise eval chokes
            AltText=$(echo "${ALT_TEXT}" | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/—/g' -e 's/)/—/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g')
        else
            ALT_TEXT=""
        fi
    fi
fi 

# loop through array of services
# if equivalent in the on array is TRUE, then source and call
# "$pubtime" "$title" "$description" "$link" "$hashtags" "$cw"  "${imgurl}" "ALT_TEXT"
description="${TootText}"
imgurl="${SendImage}"
echo "$pubtime" "$title" "$description" "$link" "$hashtags" "$cw"  "${imgurl}" "$ALT_TEXT"

for i in "${!services_on_array[@]}"; do
    if [[ "${services_on_array[i]}" == "TRUE" ]]; then
        loud "Processing ${services_array[i]}..."
        send_funct=$(echo "${services_array[i]}_send")
        source "${SCRIPT_DIR}/out_avail/${services_array[i]}.sh"
        eval ${send_funct}
        sleep 5
    fi
done
        
if [ -f "$SendImage" ];then
    rm -rf "${SendImage}"
fi
