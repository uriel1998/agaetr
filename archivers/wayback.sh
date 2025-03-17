#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################


function wayback_send {
    binary=$(grep 'waybackpy =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    outstring=$(echo "$binary -s --url ${link}")
    #echo "${outstring}"
    # except we WANT this return -- this returns the archiveis URL, which we need to pass back.
    # so assign to a GLOBAL variable that gets passed out.  error handling done by the calling script
    # https://stackoverflow.com/questions/12451278/capture-stdout-to-a-variable-but-still-display-it-in-the-console
    exec 5>&1
    IARCHIVE=$(/usr/bin/timeout -k 60 eval "${outstring}" | head -n 2 | tail -n 1 >&5)

#Archive URL:
#https://web.archive.org/web/20250307205449/https://ideatrash.net/
#Cached save:
#False
 

}

##############################################################################
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
$(return >/dev/null 2>&1)

# What exit code did that give?
if [ "$?" -eq "0" ];then
    echo "[info] Function wayback ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        if [ "${1}" == "--loud" ];then
            LOUD=1
            shift
        else
            LOUD=0
        fi    
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        wayback_send
    fi
fi

