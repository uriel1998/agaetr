#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################


function loud() {
	if [ "$LOUD" != "" ];then
		if [ $LOUD -eq 1 ];then
			echo "$@" 1>&2
		fi
    fi
}

# should have been passed in, but just in case...

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi

inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"

function xmpp_send {
	
	loud "[info] Validating go-sendxmpp availability"
	if ! command -v go-sendxmpp >/dev/null 2>&1; then
		loud "Error: go-sendxmpp not found in PATH" 
		exit 1
	fi

	JID=$(grep 'JID=' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
	JPW=$(grep 'JPW=' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
	JCONFERENCE=$(grep 'JCONFERENCE=' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
	
	if [ "$title" == "$link" ];then
        title=""
    fi

	loud "[info] Posting to jabber"
	MESSAGE=$(printf "%s\n \n%s  \n%s  \n%s  \n%s  " "${title}" "${description}" "${description2}" "${link}" "${hashtags}")
	if ! printf '%s\n' "$MESSAGE" | go-sendxmpp -u "$JID" -p "$JPW" -c "${JCONFERENCE}" >/dev/null 2>&1; then
		loud "[ERROR] Failed sending to direct target '$JCONFERENCE'" 
		SEND_FAILED=1
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
    echo "[info] Function xmpp ready to go."
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
        else
            title="${1}"
        fi
        xmpp_send "${title}"
    fi
fi
