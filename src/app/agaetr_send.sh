#!/bin/bash



# need to restructure this for multiple command line arguments, plus put file 
# header because I'm cool like that now

#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=0

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [ ! -d "${XDG_CONFIG_HOME}" ];then
    export XDG_CONFIG_HOME="${HOME}/.config"
fi

if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "INI not located; betcha nothing else is set up."
    exit 89
fi
if [ ! -f "${XDG_DATA_HOME}/agaetr/posts.db" ];then
    echo "Post database not located, exiting."
    exit 99
fi

if [ "$1" != "" ];then
    if [ "$1" == "--verbose" ];then
        shift
        LOUD=1
    fi

    # if $1 exists, it's from the single processor, and use that 
    # instead of rotating the db but add it to the posted list
    instring="${@}"
else
    mv "${XDG_DATA_HOME}/agaetr/posts.db" "${XDG_DATA_HOME}/agaetr/posts_back.db"
    tail -n +2 "${XDG_DATA_HOME}/agaetr/posts_back.db" > "${XDG_DATA_HOME}/agaetr/posts.db"
    instring=$(head -1 "${XDG_DATA_HOME}/agaetr/posts_back.db")
    rm "${XDG_DATA_HOME}/agaetr/posts_back.db"
fi

if [ -z "$instring" ];then 
    loud "Nothing to post."
    exit
fi

#Adding string to the "posted" db
echo "$instring" >> "${XDG_DATA_HOME}/agaetr/posted.db"


OIFS=$IFS
IFS='|'
myarr=($(echo "$instring"))
IFS=$OIFS

#20181227091253|Bash shell find out if a variable has NULL value OR not|https://www.cyberciti.biz/faq/bash-shell-find-out-if-a-variable-has-null-value-or-not/||None|None|#bash shell #freebsd #korn shell scripting #ksh shell #linux #unix #bash shell scripting #linux shell scripting #shell script

#pulling array into named variables so they work with sourced functions

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

# Deshortening, deobfuscating, and unredirecting the URL with muna
url="$link"
source "$SCRIPT_DIR/muna.sh"
unredirector
link="$url"


# SHORTENING OF URL
# call first (should be only) element in shortener dir to shorten url

if [ "$(ls -A "$SCRIPT_DIR/short_enabled")" ]; then
    shortener=$(ls -lR "$SCRIPT_DIR/short_enabled" | grep ^l | awk '{print $9}')
    if [ -z "$shortener" ];then
        loud "No URL shortening performed."
    else
        if [ "$shortener" != ".keep" ];then 
            short_funct=$(echo "${shortener%.*}_shortener")
            source "$SCRIPT_DIR/short_enabled/$shortener"
            url="$link"
            loud "$SCRIPT_DIR/short_enabled/$shortener"
            eval ${short_funct}
            link="$shorturl"
            loud "$shorturl"
            loud "$link"
        fi
    fi
fi

    
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
