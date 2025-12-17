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

function matrix_send
{
	if [ "$title" == "$link" ];then
        title=""
    fi
	MATRIXSERVER=$(grep 'MATRIXSERVER' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
	MAUBOT_STATUS_WEBHOOK_INSTANCE=$(grep 'MAUBOT_STATUS_WEBHOOK_INSTANCE' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

	loud "[info] Posting reply to maubot"
	jtitle="${title}"
	jbody=$(printf "%s  \n%s  \n%s  \n%s  " "${description}" "${description2}" "${link}" "${hashtags}"
#   Build the JSON safely with jq
	json_payload=$(jq -n --arg title "${jtitle}" --arg body "${jbody}" '{ title: $title,body: $body}')

	# Then send it with curl
	curl -X POST -H "Content-Type: application/json" "${MATRIXSERVER}/_matrix/maubot/plugin/${MAUBOT_STATUS_WEBHOOK_INSTANCE}/send" -d "$json_payload"

	export poster_result_code=$?

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
    echo "[info] Function email ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        if [ "${1}" == "--loud" ];then
            LOUD=1
            shift
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
        matrix_send "${title}"
    fi
fi
