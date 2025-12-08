#!/usr/bin/bash

##############################################################################
#
#  This is for taking the daily posts, cleaning it up for email sending
#  and then sending it to a reciepient, such as a blog or special someone.
#  It is designed to be called *separately* by cron.
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

function loud() {
	if [ "$LOUD" != "" ];then
		if [ $LOUD -eq 1 ];then
			echo "$@" 1>&2
		fi
    fi
}



##############################################################################
#
# Script Enters Here
#
##############################################################################

## What do we know?

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [ ! -d "${XDG_CONFIG_HOME}" ];then
    export XDG_CONFIG_HOME="${HOME}/.config"
fi



if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "INI not located. Exiting." >&2
    exit 89
else
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
fi
# Where are the stored daily posts located?
path=$(grep 'daily_posts =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
workdir=$(realpath "${path}")


if [ $(grep -c 'daily_email_to' "${inifile}") -eq 0 ];then
    loud "[ERROR] addresses to send to not set in ini."
    exit 99
fi

raw_emails=$(grep 'daily_email_to' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
email_from=$(grep 'email_from' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
if [ "${raw_emails}" == "" ];then
    loud "[ERROR] addresses to send to not set in ini."
    exit 99
fi

# Split raw CSV of of emails into actual email addresses
OIFS="$IFS"
IFS=';' read -ra email_addresses <<< "${raw_emails}"
IFS="$OIFS"

# Prettyfy text here



    for email_addy in ${email_addresses[@]}
    do
        (
            echo "From: ${email_from}"
            echo "To: ${email_addy}"
            echo "Subject: This is your daily links file."
            echo
            cat ~/.local/share/agaetr/20251207.md
        ) | /usr/sbin/sendmail -t -f "steven@stevesaus.com"
