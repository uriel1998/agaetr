#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

function archiveis_send {
    
    binary=$(grep 'archiveis =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

    outstring=$(echo "$binary ${link} -ua \"Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0\"")
    # so assign to a GLOBAL variable that gets passed out. Error handling done by the calling script.
    # https://stackoverflow.com/questions/12451278/capture-stdout-to-a-variable-but-still-display-it-in-the-console
    exec 5>&1
    ARCHIVEIS=$(eval "${outstring}" >&5)
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
    echo "[info] Function archiveis ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        archiveis_send
    fi
fi
