#!/bin/bash

##############################################################################
#
#  shortening script
#  (c) Steven Saus 2020
#  Licensed under the MIT license
#
##############################################################################

#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=1

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function yourls_shortener {

# for if URL is > what the shortening is (otherwise you'll lose real data later)

if [ $(grep -c yourls_api "${XDG_CONFIG_HOME}/agaetr/agaetr.ini") -gt 0 ];then 
    
    yourls_api=$(grep yourls_api "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g'| awk -F '=' '{print $2}')
    yourls_site=$(grep yourls_site "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    wget_bin=$(which wget)
    yourls_string=$(printf "%s \"%s/yourls-api.php?signature=%s&action=shorturl&format=simple&url=%s\" -O- --quiet" "${wget_bin}" "${yourls_site}" "${yourls_api}" "${link}")
    loud "${yourls_string}"
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
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
$(return >/dev/null 2>&1)

# What exit code did that give?
if [ "$?" -eq "0" ];then
    echo "[info] Function ready to go."
    OUTPUT=0
else
    OUTPUT=1
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        else 
            title="${1}"
        fi
        yourls_shortener "${link}"
    fi
fi
