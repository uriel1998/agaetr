#!/bin/bash

##############################################################################
#
#  Single URL preprocessor file for agaetr
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
#  For when you want to send a single URL right then.
#
###############################################################################

#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi

INI_URL=""
INI_URL="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"

QUEUE=0

URL=""

while [ $# -gt 0 ]; do
    option="$1"
    case $option in
        --queue)
                QUEUE=1
                ;;
        --url)
                shift
                URL="${1}"
                ;;
        *)      URL="${1}" 
                ;;
    esac
done
    

if [ "$URL" == "" ];then
    echo "No URL passed."
    exit 99
fi

# everything else...? 
# title="${@:2}"

# passing published time (from dd MMM)
posttime=$(date +%Y%m%d%H%M%S)
# If no title, get one
# from https://unix.stackexchange.com/questions/103252/how-do-i-get-a-websites-title-using-command-line
if [ -z "$title" ]; then
    title=$(wget -qO- "$link" | awk -v IGNORECASE=1 -v RS='</title' 'RT{gsub(/.*<title[^>]*>/,"");print;exit}' | sed 's|["]|“|g' | sed 's|['\'']|’|g'| recode html.. )
fi
link=$("${SCRIPT_DIR}"/muna.sh "${URL}")
#cw=$(echo "${myarr[3]}")
#imgurl=$(echo "${myarr[5]}")
#imgalt=$(echo "${myarr[4]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
#hashtags=$(echo "${myarr[6]}")
if [ -z "$description" ]; then
    description=$(wget -qO- "$link" | grep -e 'name="description"' | awk -F 'content=' '{ print $2 }' | awk -F '"' '{print $2}'| sed 's|["]|“|g' | sed 's|['\'']|’|g'| recode html..)
fi


# write it out as a string



#f.write(thetime + "|" + post.title + "|" + post.link + "|" + "|" + str(imgalt) + "|" + str(imgurl) + "|" + HashtagsString + "|" + str(post_description) + "\n")



outstring=$(printf "%s|%s|%s||||||%s" "${posttime}" "${title}" "${link}" "${description}")

if [ $QUEUE -eq 0 ];then
    # hook into agaetr_send.sh 
    "${SCRIPT_DIR}"/agaetr_send.sh "${outstring}"
else
    if [ ! -f "${XDG_DATA_HOME}/agaetr/posts.db" ];then
        echo "Post database not located, exiting."
        exit 99
    else
        echo "${outstring}" >> "${XDG_DATA_HOME}/agaetr/posts.db"
    fi
fi
