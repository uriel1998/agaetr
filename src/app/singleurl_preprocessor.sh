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

if [ -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
    INI_URL="${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    else
    if [ -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
        INI_URL="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
fi

# get the url that has been piped in
# run through muna

"${SCRIPT_DIR}"/muna.sh "${URL}"
# If no title, get one
# from https://unix.stackexchange.com/questions/103252/how-do-i-get-a-websites-title-using-command-line
if [ -z "$title" ]; then
    title=$(wget -qO- "$link" | awk -v IGNORECASE=1 -v RS='</title' 'RT{gsub(/.*<title[^>]*>/,"");print;exit}' | recode html.. )
fi

# get what info you can (see newsbeuter_dangerzone)
# optionally prompt for more
# write it out as a string
# hook into agaetr_send.sh (add a function in there so that if it's got a $1 then skip the db file)

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
