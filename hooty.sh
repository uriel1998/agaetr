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
Need_Image=""
IMAGE_FILE=""
LOUD=0
wget_bin=$(which wget)
python_bin=$(which python3)
declare -a services_array=()
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
    export XDG_CACHE_HOME="${HOME}/.cache"
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
    
fi

function loud() {
##############################################################################
# loud outputs on stderr 
##############################################################################    
    if [ $LOUD -eq 1 ];then
        echo "$@" 1>&2
    fi
}

posters=$(ls -A "$SCRIPT_DIR/out_enabled") 
# Loop through files in the subdirectory (excluding .keep)
for file in $posters; do
    if [ "$file" != ".keep" ];then 
        loud "Adding option ${file%.*}..."
        filename_no_ext=$(echo "${file%.*}")
        # Add to array
        services_array+=("$filename_no_ext")
        # Append to string (space-separated)
        services_string+="--field=$filename_no_ext:CHK TRUE "
    fi
done
# Trim trailing space
services_string="${services_string% }"

if [ -f "${1}" ];then
    IMAGE_FILE="${1}"
    Need_Image="TRUE"
fi

ANSWER=$(yad --geometry=+200+200 --form --separator="±" --item-separator="," --on-top --title "patootie" --field="What to post?:TXT" "" --field="ContentWarning:CBE" none,discrimination,bigot,uspol,medicine,violence,reproduction,healthcare,LGBTQIA,climate,SocialMedia -columns=2  --field="Attachment?":CHK "${Need_Image}" ${services_string} --item-separator="," --button=Cancel:99 --button=Post:0)
 
# Make our services on/off array:
OIFS=$IFS
IFS='±' read -r -a temp_array <<< "${ANSWER}"
# Create a new array ignoring the first three entries (since they're not services)
services_on_array=("${temp_array[@]:3}")
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

if [ "$IMAGE_FILE" == "" ];then  # if there wasn't one by command line
    # to see if need to select image
    Need_Image=$(echo "$ANSWER" | awk -F '±' '{print $3}')
fi

if [ "${Need_Image}" == "TRUE" ];then 
    if [ "${IMAGE_FILE}" == "" ]; then # if there wasn't one by command line
        IMAGE_FILE=$(yad --geometry=+200+200  --on-top --title "Select image to add" --width=500 --height=400 --file --file-filter "Graphic files | *.jpg *.png *.webp *.jpeg")
    fi
    if [ ! -f "${IMAGE_FILE}" ];then
        SendImage=""
    else
        # resizing will be handled by out modules.
        filename=$(basename -- "$IMAGE_FILE")
        extension="${filename##*.}"
        SendImage=$(mktemp --suffix=.${extension})
        cp "${IMAGE_FILE}" "${SendImage}"
        ALT_TEXT=$(yad --geometry=+200+200 --window-icon=musique --on-top --skip-taskbar --image-on-top --borders=5 --title "Choose your alt text" --image "${SendImage}" --form --separator="" --item-separator="," --text-align=center --field="Alt text to use?:TXT" "I was too lazy to put alt text" --item-separator="," --separator="")
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
        source "${SCRIPT_DIR}/out_enabled/${services_array[i]}.sh"
        eval ${send_funct}
        sleep 5
    fi
done
        
if [ -f "$SendImage" ];then
    rm -rf "${SendImage}"
fi
