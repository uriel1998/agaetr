#!/bin/bash

##############################################################################
#  agaetr_send.sh
#  (c) Steven Saus 2023
#  Licensed under the Apache license
#
##############################################################################

# Set defaults and global variables so they can be passed back and forth 
# en masse between functions and sourced scripts

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=0
prefix=""
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

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [ ! -d "${XDG_CONFIG_HOME}" ];then
    export XDG_CONFIG_HOME="${HOME}/.config"
fi


function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

function get_instring() {

    mv "${XDG_DATA_HOME}/agaetr/${prefix}posts.db" "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db"
    tail -n +2 "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db" > "${XDG_DATA_HOME}/agaetr/${prefix}posts.db"
    instring=$(head -1 "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db")
    rm "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db"


    if [ -z "$instring" ];then 
        loud "Nothing to post."
        exit
    fi

    #Adding string to the "posted" db
    echo "$instring" >> "${XDG_DATA_HOME}/agaetr/${prefix}posted.db"
    
}

function parse_instring() {
    OIFS=$IFS
    IFS='|'
    myarr=($(echo "$instring"))
    IFS=$OIFS

    # pulling array into named variables so they work with sourced functions
    # these are all set as global variables so they can be sent to sourced functions

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
}

function check_image() {
    
    if [ "$imgurl" = "None" ];then 
        imgurl=""
    fi
    if [ "$imgalt" = "None" ];then 
        imgalt=""
    fi

    #Checking the image url before sending it to the client
    imagecheck=$(wget -q --spider "${imgurl}"; echo $?)

    if [ "${imagecheck}" -ne 0 ];then
        loud "Image no longer available; omitting."
        imgurl=""
        imgalt=""
    fi
}

function yourls_shortener {

# for if URL is > what the shortening is (otherwise you'll lose real data later)

if [ $(grep -c yourls_api "${XDG_CONFIG_HOME}/cw-bot/${prefix}cw-bot.ini") -gt 0 ];then 
    
    yourls_api=$(grep yourls_api "${XDG_CONFIG_HOME}/cw-bot/${prefix}cw-bot.ini" | sed 's/ //g'| awk -F '=' '{print $2}')
    yourls_site=$(grep yourls_site "${XDG_CONFIG_HOME}/cw-bot/${prefix}cw-bot.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    wget_bin=$(which wget)
    yourls_string=$(printf "%s \"%s/yourls-api.php?signature=%s&action=shorturl&format=simple&url=%s\" -O- --quiet" "${wget_bin}" "${yourls_site}" "${yourls_api}" "${link}")
    shorturl=$(eval "${yourls_string}")  
    if [ ${#link} -lt 10 ];then # it didn't work 
        loud "Shortner failure, using original URL of"
        loud "$link"
    else
        # may need to add verification that it starts with http here?
        loud "Using shortened link $shorturl"
        link=$(echo "$shorturl")
    fi
else
    # no configuration found, so just passing it back.
    loud "Shortener configuration not found, using original URL of" 
    loud "$link"
fi

}


##############################################################################
# 
# Script Enters Here
# 
##############################################################################

# parse command line options
#
while [ $# -gt 0 ]; do
    option="$1"
    case $option in

    --help) 
        display_help
        exit
        ;;        
    --verbose) 
        LOUD=1
        shift 
        ;;        
    --prefix) 
        shift 
        prefix="${1}"
        shift
        ;;                
    esac
done

if [ ! -f "${XDG_CONFIG_HOME}/agaetr/${prefix}agaetr.ini" ];then
    echo "INI not located. Exiting." >&2
    exit 89
fi
if [ ! -f "${XDG_DATA_HOME}/agaetr/${prefix}posts.db" ];then
    echo "Post database not located, exiting." >&2
    exit 99
fi

get_instring
parse_instring
check_image


# Deshortening, deobfuscating, and unredirecting the URL with muna
url="$link"
source "$SCRIPT_DIR/muna.sh"
unredirector
link="$url"


# SHORTENING OF URL - moved to function here b/c only yourls is supported.

if [ ${#link} -gt 36 ]; then 
    loud "Sending to shortener function"
    yourls_shortener
fi

    
#### TODO URGENTLY MOTHERFUCKER    
# ack - need to have out determined by the ini files, and haven't sorted that yet.    
    
# Parsing enabled out systems. Find files in out_enabled, then import 
# functions from each and running them with variables already established.

posters=$(ls -A "$SCRIPT_DIR/out_enabled")

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
