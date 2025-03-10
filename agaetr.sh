#!/bin/bash

##############################################################################
#
#  agaetr -- to take in RSS feeds and single URL input, preprocess, and to 
#  output to a number of social media outputs
#  (c) Steven Saus 2025
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
    echo "# --locations: print config and data locations"
    echo "# --readme: display the README on the console"
    echo "# Usage ###########################################################"    
    echo "# --pull: draw in configured RSS sources"
    echo "# --push: push out from queue"
    echo "# --muna [URL]: unredirect a URL "
    echo "# --url [URL] --description [text]: add single url to outbound queue "    
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

 

 

add_single_url(){
    # okay, so there's always going to be some weird escaping...
    string_in="${@}"
    if [ $(echo "${string_in}" | grep -c "--description") -neq 0 ];then
        single_url=$(echo "${string_in}" | awk -F '--description' '{ print $1 }' )
        description=$(echo "${string_in}" | awk -F '--description' '{ print $2 }')
    else
        single_url=$(echo "${string_in}" | awk -F '--url' '{print $2}')
    fi
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
                    eval agaetr_send.sh
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
