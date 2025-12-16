#!/usr/bin/bash

##############################################################################
#
#  This is for taking the daily posts, cleaning it up for email sending
#  and then sending it to a reciepient, such as a blog or special someone.
#  It is designed to be called *separately* by cron.
#  This is specifically for a Postie configuration with wordpress or the like
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=1

function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
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

loud "[info] Setting up for email to blog."

if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "INI not located. Exiting." >&2
    exit 89
else
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
fi
# Where are the stored daily posts located?
path=$(grep 'daily_posts' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
workdir=$(realpath "${path}")
sent_days_db="${XDG_DATA_HOME}/agaetr/daily_blog_posts_sent.db"

if [ $(grep -c 'daily_blog_email_to' "${inifile}") -eq 0 ];then
    loud "[ERROR] addresses to send to not set in ini."
    exit 99
fi

email_to=$(grep 'daily_blog_email_to' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
email_from=$(grep 'blog_email_from' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
today="$(date +%Y%m%d)"

for file in "${workdir}"/*.md; do
    # Skip literal pattern if no files match
    [ -e "${file}" ] || continue
	loud "[info] Processing ${file}."
    base="$(basename -- "${file}")"

    if [[ "${base}" =~ ^[0-9]{8}\.md$ ]]; then
		day="${base%%.md}"
		outfile=$(mktemp)
		# Skip today
        if [[ "${day}" = "${today}" ]]; then
            continue
        fi

        # Skip if already in sent_days_db
        if grep -Fxq "${base}" "${sent_days_db}"; then
            continue
        fi
		# Valid file to send, Prettyfy text here
		# Strip directory path, leaving only the basename
		base="$(basename -- "${file}")"
		# Extract YYYYMMDD
		ymd="${base%%.*}"

		# Convert to RFC 2822 format at midnight local time
		email_date="$(date -d "${ymd} 00:00:00" +"%a, %d %b %Y %H:%M:%S %z")"
		short_date="$(date -d "${ymd} 00:00:00" +"%-d %b")"

	    cat "${XDG_DATA_HOME}/agaetr/daily_blog_email_header.txt" > "${outfile}"
		loud "[info] Getting AI summary of post."
		summary=$(${SCRIPT_DIR}/ai_gen_summary_text.sh ${file})
		if [ $? != 1 ];then
			loud "[info] Got AI summary of post."
			printf "<p><b>TL;DR</b>: %s</p></div><div>" "${summary}" >> "${outfile}"
		else
			loud "[warn] Failed getting AI summary of post; falling back to default."
			printf "<p>This is a roundup of things I found around the internet that I thought were neat or noteworthy in some way and shared to social media.</p></div><div>\n"  >> "${outfile}"
		fi
		loud "[info] Converting text."
		pandoc -f gfm -t html -i "${file}" | sed 's#<hr />#</div><div>#g' >> "${outfile}"
		# With new versions of fortune-mod you have to explicitly point it at a fortune file.
		# TODO - fix so it's configurable
		loud "[info] Adding fortune."
	    quote=$($(which fortune) /home/steven/vault/fortunes/grunkle)
	    if [ $? != 1 ];then
	        # TODO - customize this, but basically have a quotation here.
			printf "<h2>Quote of the Day:</h2><b>%s</b></div><div>" "${quote}" >> "${outfile}"
		else
			loud "[warn] fortune not added."
		fi
		loud "[info] Adding footer."
	    cat "${XDG_DATA_HOME}/agaetr/daily_blog_email_footer.txt" >> "${outfile}"

		loud "[info] Sending email that would have date of ${email_date}."
		(
		echo "From: ${email_from}"
		echo "To: ${email_to}"
		echo "Date: ${email_date}"
		echo "Subject: Roundup of links for ${short_date}."
		echo "Content-Type: text/html; charset=UTF-8"
		echo "MIME-Version: 1.0";
		echo
		cat "${outfile}"	) | /usr/sbin/sendmail -t -f "steven@stevesaus.com"
		if [ "$?" == "0" ];then
			loud "[info] email sent."
			echo "${base}" >> "${sent_days_db}"
			rm "${outfile}"
		else
			loud "[warn] Sending email failed!"
		fi
    fi
done
if [ -f "${outfile}" ];then
	rm -rf "${outfile}"
fi
