#!/bin/bash

##############################################################################
#
#  agaetr -- to take in RSS feeds and single URL input, preprocess, and to 
#  output to a number of social media outputs
#  (c) Steven Saus 2024
#  Licensed under the MIT license
#
##############################################################################


###############################################################################
# Establishing XDG directories, or creating them if needed.
# standardized binaries that should be on $PATH
# Likewise with initial INI files
############################################################################### 
VERSION="0.1.0"
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=0
wget_bin=$(which wget)
python_bin=$(which python3)



if [ -z "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
    export XDG_CONFIG_HOME="${HOME}/.config"
    export XDG_CACHE_HOME="${HOME}/.cache"
fi

if [ ! -d "${XDG_CONFIG_HOME}" ];then
    echo "Your XDG_CONFIG_HOME variable is not properly set and does not exist."
    exit 99
fi

function loud() {
##############################################################################
# loud outputs on stderr 
##############################################################################    
    if [ $LOUD -eq 1 ];then
        echo "$@" 1>&2
    fi
}

check_for_config(){
##############################################################################
# Make sure the config is there
##############################################################################    
    if [ ! -d "${XDG_CONFIG_HOME}/agaetr" ];then
        mkdir -p "${XDG_CONFIG_HOME}/agaetr"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
        cp /app/etc/agaetr.ini "${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
        cp /app/etc/empty_feeds.ini "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/cw.ini" ];then
        cp /app/etc/cw.ini "${XDG_CONFIG_HOME}/agaetr/cw.ini"
    fi        
    if [ ! -d "${XDG_DATA_HOME}/agaetr" ];then
        mkdir -p "${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -f "${XDG_DATA_HOME}/agaetr/README.md" ];then
        cp /app/share/agaetr/README.md "${XDG_DATA_HOME}/agaetr/README.md"
    fi        
    if [ ! -f "${XDG_DATA_HOME}/agaetr/LICENSE.md" ];then
        cp /app/share/agaetr/LICENSE.md "${XDG_DATA_HOME}/agaetr/LICENSE.md"
    fi        
}

display_help(){
##############################################################################
# Show the Help
##############################################################################    
    echo "###################################################################"
    echo "# Standalone: /path/to/agaetr.sh [options]"
    echo "# Info ############################################################"
    echo "# --help:  show help "
    echo "# --configure: enter configurator"
    echo "# --locations: print config and data locations"
    echo "# --readme: display the README on the console"
    echo "# Usage ###########################################################"    
    echo "# --pull: draw in configured RSS sources"
    echo "# --push: push out from queue"
    echo "# --muna [URL]: unredirect a URL "
    echo "# --version: report version  "
    echo "###################################################################"
}

display_readme(){
##############################################################################
# Show the README
##############################################################################
    if [ -f "${XDG_DATA_HOME}"/agaetr/README.md ];then
        ${PAGER:-more} < "${XDG_DATA_HOME}"/agaetr/README.md
        ${PAGER:-more} < "${XDG_DATA_HOME}"/agaetr/LICENSE.md
    else
        if [ -f "${SCRIPT_DIR}/README.md" ];then
            ${PAGER:-more} < ${SCRIPT_DIR}/README.md
            ${PAGER:-more} < ${SCRIPT_DIR}/LICENSE.md
        else
            echo "README.md not found!"
            exit 99
        fi
    fi
    exit
}



configurators(){  
##############################################################################
# Invoke the configurators
##############################################################################

# -- chose from existing inis or proffer to make new one
# TODO -- add in configurator for matrix, archiveis  
    echo "Which would you care to configure?"
    select module in cookies shaarli wallabag mastodon email twitter wayback save feeds quit
    do
    
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"  
    case ${module} in
        "feeds") 
            writefeed=""
            feednum=$(date +%Y%m%d%H%m%S)
            writefeed=$(printf "%s\n[Feed%s]" "${writefeed}" "${feednum}")
            echo "Does this feed require preprocessing [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                echo "Please enter the original source of the feed with leading https://."
                read src
                writefeed=$(printf "%s\nsrc = %s" "${writefeed}" "${src}")
                echo "Please enter the command to use for preprocessing."
                # IFS change so we can get quotes, I hope
                OIFS=$IFS
                IFS=$'\n'
                read cmd
                writefeed=$(printf "%s\ncmd = %s" "${writefeed}" "${cmd}")
                IFS=$OIFS
                echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                read url
                writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
            else
                echo "Is this feed from a file? [y/N]?"
                read ans
                if [ "$ans" == "y" ];then
                    echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                    read url
                    writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
                else
                    echo "Please enter the source of the feed, with leading https://"
                    read url
                    # check for starting with http? 
                    writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
                fi
            fi
            echo "Should the feed images be marked sensitive by default? [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                writefeed=$(printf "%s\nsensitive = yes" "${writefeed}")
            else
                writefeed=$(printf "%s\nsensitive = no" "${writefeed}")
            fi
            echo "What should the content warning on every post from this feed be?"
            echo "Leave blank for no automatic warning on EVERY post from this feed."
            read ans
            if [ "$ans" != "" ];then
                writefeed=$(printf "%s\nContentWarning = yes" "${writefeed}")
                writefeed=$(printf "%s\nGlobalCW = %s" "${writefeed}" "${ans}")
            else
                writefeed=$(printf "%s\nContentWarning = no" "${writefeed}")
                writefeed=$(printf "%s\nGlobalCW = " "${writefeed}")
            fi
            echo "This is the proposed configuration:"
            echo -e "${writefeed}"
            echo "Is this acceptable? [y/N]"
            read ans
            if [ "${ans}" == "y" ];then
                # write it all to the feed ini file
                printf "%s\n" "${writefeed}" >> "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
            else
                echo "Aborting."
            fi
            ;;
        "wayback") 
            echo "You must register for an API key at https://archive.org/account/s3.php"
            echo "Please input the access key"
            read accesskey
            echo "Please input the secret key"
            read accesssecret          
            eval $(printf "sed -i \'/^wayback_access =.*/s/.*/wayback_access = \"${accesskey}\"/' ${inifile}")
            eval $(printf "sed -i \'/^wayback_secret =.*/s/.*/wayback_secret = \"${accesssecret}\"/' ${inifile}")
            ;;
        "cookies") 
            if [ ! -f "${XDG_CONFIG_HOME}/cookies.txt" ];then
                echo "Please copy your cookie file to ${XDG_CONFIG_HOME}/cookies.txt"
            else
                echo "Cookie file already exists at ${XDG_CONFIG_HOME}/cookies.txt"
            fi
            ;;
        "wallabag") 
            binary=$(grep 'wallabag =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default wallabag binary with ${binary} found on $PATH"
                    eval $(printf "sed -i \'/^wallabag =.*/s/.*/wallabag = \"${binary}\"/' ${inifile}")
                else
                    echo "No wallabag binary found!"
                    exit 99
                fi
            fi
            eval $("${binary}" config)
            ;;

        "mastodon") 
            binary=$(grep 'toot =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default toot binary with ${binary} found on $PATH"
                    eval $(printf "sed -i \'/^toot =.*/s/.*/toot = \"${binary}\"/' ${inifile}")
                else
                    echo "No toot binary found!"
                    exit 99
                fi
            fi
            eval $("${binary}" login_cli)
            ;;
        "shaarli") 
            binary=$(grep 'shaarli =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default shaarli binary with ${binary}"
                    eval $(printf "sed -i \'/^shaarli =.*/s/.*/shaarli = \"${binary}\"/' ${inifile}")
                else
                    echo "No shaarli binary found!"
                    exit 99
                fi
            fi
            config_number=$(grep -c 'shaarli_config' "${inifile}")
            echo "Please give this configuration a name."
            read shaarli_name
            echo "Please put the URL of your shaarli instance with leading https://"
            read shaarli_url
            echo "Please input the API secret (under Tools, Configure)"
            read shaarli_secret
            shaarli_config="${XDG_CONFIG_HOME}/shaarli/agaetr_shaarli${config_number}.cfg"
            echo "[shaarli]" > "${shaarli_config}"
            echo "${shaarli_url}" >> "${shaarli_config}"
            echo "${shaarli_secret}" >> "${shaarli_config}"
            echo " " >> "${inifile}"
            echo "[shaarli_config ${shaarli_name}]" >> "${inifile}"
            echo "shaarli_config = ${shaarli_config}" >> "${inifile}"
            ;;
        "email")
            echo "Please put the name or address of your SMTP server (NOT port)"
            read smtp_server
            echo "Please input the port of your SMTP server"
            read smtp_port
            echo "Please input the SMTP username"
            read smtp_username
            echo "Please input the SMTP user password"
            read smtp_password       
            inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
            TempVar=$(cat "${inifile}" | grep -v smtp_)
            echo "${TempVar}" > "${inifile}"
            echo "smtp_server = ${smtp_server}" >> "${inifile}"
            echo "smtp_port = ${smtp_port}" >> "${inifile}"
            echo "smtp_username = ${smtp_username}" >> "${inifile}"
            echo "smtp_password = ${smtp_password}" >> "${inifile}"
            ;;
        "save")
            echo "All saved files  stored under ${XDG_DATA_HOME}/agaetr"
            echo "If you would like to have a symlink, type"
            echo "ln -s ${XDG_DATA_HOME}/agaetr /desired/path"
            ;;
        *) echo "Exiting configuration." break ;;
    esac
    done
}

function push_get_instring() {
    tempstring=""
    mv "${XDG_DATA_HOME}/agaetr/posts.db" "${XDG_DATA_HOME}/agaetr/posts_back.db"
    tail -n +2 "${XDG_DATA_HOME}/agaetr/posts_back.db" > "${XDG_DATA_HOME}/agaetr/posts.db"
    tempstring=$(head -1 "${XDG_DATA_HOME}/agaetr/posts_back.db")
    rm "${XDG_DATA_HOME}/agaetr/posts_back.db"
    if [ -z "$tempstring" ];then 
        loud "Nothing to post."
        
    else
        #Adding string to the "posted" db
        echo "${tempstring}" >> "${XDG_DATA_HOME}/agaetr/posted.db"
        return "${tempstring}"
    fi
}

function yourls_shortener {
    local link="${1}"
    if [ $(grep -c yourls_api "${XDG_CONFIG_HOME}/agaetr/agaetr.ini") -gt 0 ];then     
        yourls_api=$(grep yourls_api "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g'| awk -F '=' '{print $2}')
        yourls_site=$(grep yourls_site "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
        yourls_string=$(printf "%s \"%s/yourls-api.php?signature=%s&action=shorturl&format=simple&url=%s\" -O- --quiet" "${wget_bin}" "${yourls_site}" "${yourls_api}" "${local_link}")
        shorturl=$(eval "${yourls_string}")  
        if [ ${#link} -lt 10 ];then # it didn't work 
            loud "Shortner failure, using original URL of"
            loud "${local_link}"
            echo "${local_link}"
        else
            # may need to add verification that it starts with http here?
            loud "Using shortened link $shorturl" 
            echo "${shorturl}"
        fi
    else
        # no configuration found, so just passing it back.
        loud "Shortener configuration not found, using original URL of" 
        loud "${local_link}" 
        echo "${local_link}"
    fi
}


push_send(){
    
    # initialize our variables
    instring=""
    posttime=""
    posttime2=""
    pubtime=""
    title=""
    link=""
    cw=""
    imgurl=""
    imgalt=""
    hashtags=""
    description=""
    
    # get string from queue
    instring=$(push_get_instring)
    
    # parsing instring
    OIFS=$IFS
    IFS='|'
    myarr=($(echo "$instring"))
    IFS=$OIFS

    # passing published time (from dd MMM)
    posttime=$(echo "${myarr[0]}")
    posttime2="${posttime::-6}"
    pubtime=$(date -d"$posttime2" +%d\ %b)
    title=$(echo "${myarr[1]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    link=$(echo "${myarr[2]}")
    cw=$(echo "${myarr[3]}")
    imgurl=$(echo "${myarr[5]}")
    imgalt=$(echo "${myarr[4]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    hashtags=$(echo "${myarr[6]}")
    description=$(echo "${myarr[7]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )

    # image processing
    if [ "$imgurl" = "None" ];then 
        imgurl=""
        imgalt=""
    else
        # There is an image url
        # Checking the image url before sending it to the client
        imagecheck=$(wget -q --spider "${imgurl}"; echo $?)
        if [ "${imagecheck}" -ne 0 ];then
            loud "Image no longer available; omitting."
            imgurl=""
            imgalt=""
        else
            #there is an image
            if [ "$imgalt" = "None" ] || [ "$imagealt" = "" ];then 
                # there is an image, no alt provided
                imgalt="Featured image pulled automatically from web."
            fi
        fi
    fi
    
    # Deshortening, deobfuscating, and unredirecting the URL with muna
    url="${link}"
    source "$SCRIPT_DIR/muna.sh"
    unredirector
    link="${url}"
    
    # SHORTENING OF URL - moved to function here b/c only yourls is supported.
    if [ ${#link} -gt 36 ]; then 
        loud "Sending to shortener function"
        link=$(yourls_shortener "${link}")
    fi
    
    # Now to send via the posting functions
    posters=$(ls -A "$SCRIPT_DIR/out_enabled")

# TODO: Explicitly pass strings to sourced functions


    for p in $posters;do
        if [ "$p" != ".keep" ];then 
            loud "Processing ${p%.*}..."
            send_funct=$(echo "${p%.*}_send")
            source "${SCRIPT_DIR}/out_enabled/${p}"
            loud "${SCRIPT_DIR}/out_enabled/${p}"
            eval ${send_funct}
            sleep 5
        fi
    done
    
}


add_single_url(){
    # okay, so there's always going to be some weird escaping...
    single_url="${1}"
    title=$(echo "${@:1}" | sed 's|["]|“|g' | sed 's|['\'']|’|g')
    posttime=$(date +%Y%m%d%H%M%S)
    # No title passed, getting direct from URL
    if [ -z "$title" ]; then
        title=$(wget -qO- "${single_url}" | awk -v IGNORECASE=1 -v RS='</title' 'RT{gsub(/.*<title[^>]*>/,"");print;exit}' | sed 's|["]|“|g' | sed 's|['\'']|’|g'| recode html.. )
    fi
    url="${single_url}"
    source "$SCRIPT_DIR/muna.sh"
    unredirector
    single_url="${url}"
    if [ -z "$description" ]; then
        description=$(wget -qO- "${single_url}" | sed 's/</\n</g' | grep -i "og:description" | awk -F "content=\"" '{print $2}' | awk -F "\">" '{print $1}' | sed 's|["]|“|g' | sed 's|['\'']|’|g'| recode html..)
        if [ "$description" == "" ];then
            description=$(wget -qO- "${single_url}" | sed 's/</\n</g' | grep -i "meta name=\"description" | awk -F "content=\"" '{print $2}' | awk -F "\">" '{print $1}' | sed 's|["]|“|g' | sed 's|['\'']|’|g'| recode html..)
        fi
    fi
    outstring=$(printf "%s|%s|%s||||||%s" "${posttime}" "${title}" "${single_url}" "${description}")
    if [ ! -f "${XDG_DATA_HOME}/agaetr/posts.db" ];then
        loud "Post database not located, exiting."
        exit 99
    else
        echo "${outstring}" >> "${XDG_DATA_HOME}/agaetr/posts.db"
    fi
}


rss_preprocessor(){
    # to preprocess any feeds that need it.
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini" 
    
    
   OIFS=$IFS
    IFS=$'\n'
    myarr=($(grep --after-context=2 -e "^src =" "${inifile}"))
    IFS=$OIFS
    # find src/cmd/url trio
    # get commands for those feeds
    # use url for output directories
    # then do this - printf if I have to in order for escapes to work
    len=${#myarr[@]}
    for (( i=0; i<$len; i=$(( i+2 )) )); do         
        if [[ "${myarr[$i]}" != "--" ]];then
            mysrc=""
            mycmd=""
            myurl=""
            thecommand=""
            j=$(( i+1 ))
            k=$(( j+1 ))
            if [[ "${myarr[$i]}" == "src"* ]];then
                mysrc=$(echo "${myarr[$i]}" | awk -F ' = ' '{print $2}')
                if [[ "${myarr[$j]}" == "cmd"* ]];then
                    mycmd=$(echo "${myarr[$j]}" | awk -F ' = ' '{print $2}')
                    if [[ "${myarr[$k]}" == "url"* ]];then
                        myurl=$(echo "${myarr[$k]}" | awk -F ' = ' '{print $2}')
                        
# TODO                        
# CHECK FOR PATH OF where it writes to!
# I think this is right
                        rel_path=$(printf "%s/agaetr%s" "${XDG_DATA_HOME}" "${myurl}")
                        just_path=$(realpath "${rel_path}" | awk -F '\/' '{$NF=""}1' | sed 's| |\/|g')
                        if [ ! -d "${just_path}" ];then
                            mkdir -p "${just_path}"
                        fi                        
                        # time to create the command string
                        thecommand=$(printf "wget -O- \"%s\" | %s > \"%s/agaetr%s\"" "${mysrc}" "${mycmd}" "${XDG_DATA_HOME}" "${myurl}")
                        #echo "${thecommand}"
                        eval "${thecommand}"
                    fi
                fi
            fi
        fi
    done
}





while [ $# -gt 0 ]; do
##############################################################################
# Get command-line parameters
##############################################################################
    option="$1"
    case $option in
    
 
    
        --loud)     export LOUD=1
                    shift
                    ;;
        --init)     display_help
                    check_for_config
                    exit
                    ;;
        --help)     display_help
                    exit
                    ;;
        --readme)   check_for_config #includes moving README!
                    display_readme
                    exit
                    ;;                    
        *muna)     # Just running muna, nothing to see here.
                    shift
                    URL="${@}"
                    "${SCRIPT_DIR}"/muna.sh "${URL}"
                    exit    
                    ;;
        --version)  echo "${VERSION}"; check_for_config; exit ;;
        --pull)     # perform a pull run. 
                    rss_preprocessor
                    "${python_bin}" "${SCRIPT_DIR}"/agaetr_parse.py                    
                    ;;
        --push)     # perform a push run.
                    push_send
                    ;;
        --url)      # ADDING a single url.                
                    shift
                    add_single_url "${@}"
                    exit
                    ;;
        --locations) 
                    # I want to check if it's using the $HOME or flatpak ones here,
                    #check_for_config
                    echo "$XDG_CONFIG_HOME"
                    echo "$XDG_DATA_HOME"
                    echo "$XDG_CACHE_HOME"
                    exit
                    ;;
        *)          shift;;
    esac
done   

# clean_temp_keyword
