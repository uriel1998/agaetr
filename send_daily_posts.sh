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
sent_days_db="${XDG_DATA_HOME}/agaetr/daily_posts_sent.db"

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
# choose day (s) to post.
    # Not today
    # not in db - basically just do a sort-and-diff on ls and that file, huh?
    # for each of those results, convert that markdown to pretty html for emails
    # then send it
    # then write that date in the db

    # assembling the email:
    #make a tempfile
    cat "${XDG_DATA_HOME}/agaetr/daily_email_header.txt" > "${outfile}"
    pandoc -f gfm -t html -i 20251206.md | sed 's#<hr />#</div><div>#g' >> "${outfile}"
    quote=$($(which fortune) /home/steven/vault/fortunes/grunkle)
    if [ $? != 1 ];then
        # TODO - customize this, but basically have a quotation here.
        printf "<h4>Quote of the Day:</h4>%s</div><div>" "${quote}" >> "${outfile}"
    fi
    cat "${XDG_DATA_HOME}/agaetr/daily_email_footer.txt" >> "${outfile}"
# Okay, this MIGHT work for Wordpress, but is shit for everyone else. So how do we make it a real html email?
    for email_addy in ${email_addresses[@]}
    do
        (
            echo "From: ${email_from}"
            echo "To: ${email_addy}"
            echo "Subject: This is your daily links file."
            echo
            cat ~/.local/share/agaetr/20251207.md
        ) | /usr/sbin/sendmail -t -f "steven@stevesaus.com"
