#!/bin/bash

##############################################################################
#
#  Sending helper script for agaetr
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
	fi
}



function surfraw_bookmark {
    echo -e "${title}\t${link}" >> ${XDG_CONFIG_DIR}/surfraw/bookmarks
    poster_result_code=0
 
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
    loud "[info] Function tumblr ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        if [ "${1}" == "--loud" ];then
            LOUD=1
            shift
        else
            if [ "$LOUD" == "" ];then
                # so it doesn't clobber exported env
                LOUD=0
            fi
        fi
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        surfraw_bookmark
    fi
