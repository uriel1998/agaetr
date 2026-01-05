#!/usr/bin/bash

##############################################################################
#
#  This is for taking the daily posts, cleaning it up for email sending
#  and then sending it to a reciepient, such as a blog or special someone.
#  It is designed to be called *separately* by cron.
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
#  FIXED VERSION - corrects logic errors in original script
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

function check_required_file() {
    local file="$1"
    local description="$2"
    if [ ! -f "$file" ]; then
        loud "[ERROR] Required $description file missing: $file"
        return 1
    elif [ ! -s "$file" ]; then
        loud "[WARN] Required $description file is empty: $file"
        return 2
    fi
    return 0
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
if [ -z "$path" ]; then
    loud "[ERROR] daily_posts path not configured in ini file"
    exit 88
fi

workdir=$(realpath "${path}")
if [ ! -d "$workdir" ]; then
    loud "[ERROR] daily_posts directory does not exist: $workdir"
    exit 87
fi

sent_days_db="${XDG_DATA_HOME}/agaetr/daily_posts_sent.db"

# Check required template files before processing
header_file="${XDG_DATA_HOME}/agaetr/daily_email_header.txt"
footer_file="${XDG_DATA_HOME}/agaetr/daily_email_footer.txt"

check_required_file "$header_file" "email header template"
if [ $? -eq 1 ]; then
    loud "[ERROR] Cannot continue without email header template"
    exit 86
fi

check_required_file "$footer_file" "email footer template"
if [ $? -eq 1 ]; then
    loud "[ERROR] Cannot continue without email footer template"
    exit 85
fi

if [ $(grep -c 'daily_email_to' "${inifile}") -eq 0 ];then
    loud "[ERROR] addresses to send to not set in ini."
    exit 99
fi

raw_emails=$(grep 'daily_email_to' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
email_from=$(grep 'daily_email_from' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
if [ "${raw_emails}" == "" ];then
    loud "[ERROR] addresses to send to not set in ini."
    exit 99
fi

# Split raw CSV of of emails into actual email addresses
OIFS="$IFS"
IFS=',' read -ra email_addresses <<< "${raw_emails}"
IFS="$OIFS"

today="$(date +%Y%m%d)"
files_processed=0

#  Flow is different here than to blog -- still loop and construct, but construct once,
# send multiple.
for file in "${workdir}"/*.md; do
    # Skip literal pattern if no files match
    [ -e "${file}" ] || continue
	loud "[info] Processing ${file}."
    base="$(basename -- "${file}")"

    if [[ "${base}" =~ ^[0-9]{8}\.md$ ]]; then
		day="${base%%.md}"

		# Skip today
        if [[ "${day}" = "${today}" ]]; then
            loud "[info] Skipping today's file: ${base}"
            continue
        fi

        # Skip if already in sent_days_db
        if grep -Fxq "${base}" "${sent_days_db}"; then
            loud "[info] Skipping already sent file: ${base}"
            continue
        fi

        # Check if source file has content
        if [ ! -s "${file}" ]; then
            loud "[WARN] Skipping empty source file: ${base}"
            continue
        fi

        outfile=$(mktemp)
        if [ ! -f "$outfile" ]; then
            loud "[ERROR] Failed to create temporary file"
            continue
        fi

		# Valid file to send, Prettify text here
		# Extract YYYYMMDD
		ymd="${base%%.*}"
		# Convert to RFC 2822 format at midnight local time
        email_date="$(date -d "${ymd} 23:59:00" +"%a, %d %b %Y %H:%M:%S %z")"
        short_date="$(date -d "${ymd} 23:59:00" +"%-d %b")"

        # Start building email content
	    cat "${header_file}" > "${outfile}"

		loud "[info] Getting AI summary of post."
		summary=""
		if [ -x "${SCRIPT_DIR}/ai_gen_summary_text.sh" ]; then
		    summary=$(${SCRIPT_DIR}/ai_gen_summary_text.sh "${file}" 2>/dev/null)
		    ai_exit_code=$?
		    # FIXED: Check for success (exit code 0), not failure
		    if [ $ai_exit_code -eq 0 ] && [ -n "$summary" ]; then
		    	loud "[info] Got AI summary of post."
		    	printf "<p><b>TL;DR</b>: %s</p></div><div>" "${summary}" >> "${outfile}"
		    else
		    	loud "[warn] Failed getting AI summary of post (exit code: $ai_exit_code); falling back to default."
		    	printf "<p>This is a roundup of things I found around the internet that I thought were neat or noteworthy in some way and shared to social media.</p></div><div>\n"  >> "${outfile}"
		    fi
		else
		    loud "[warn] AI summary script not found; using fallback."
		    printf "<p>This is a roundup of things I found around the internet that I thought were neat or noteworthy in some way and shared to social media.</p></div><div>\n"  >> "${outfile}"
		fi

		# Convert markdown to HTML and append
		if command -v pandoc >/dev/null 2>&1; then
		    pandoc_content=$(pandoc -f gfm -t html -i "${file}" 2>/dev/null)
		    if [ $? -eq 0 ] && [ -n "$pandoc_content" ]; then
		        echo "$pandoc_content" | sed 's#<hr />#</div><div>#g' >> "${outfile}"
		        loud "[info] Converted markdown content successfully"
		    else
		        loud "[warn] Pandoc conversion failed, content may be empty"
		        echo "<p><em>Content conversion failed</em></p>" >> "${outfile}"
		    fi
		else
		    loud "[error] pandoc not found, cannot convert markdown"
		    echo "<p><em>pandoc not available for content conversion</em></p>" >> "${outfile}"
		fi

		# Add fortune quote if available
		fortune_file="/home/steven/vault/fortunes/grunkle"
	    if command -v fortune >/dev/null 2>&1 && [ -f "$fortune_file" ]; then
	        # FIXED: Correct fortune command syntax
	        quote=$(fortune "$fortune_file" 2>/dev/null)
	        quote_exit_code=$?
	        # FIXED: Check for success (exit code 0), not failure
	        if [ $quote_exit_code -eq 0 ] && [ -n "$quote" ]; then
	            loud "[info] Added fortune quote"
			    printf "<h2>Quote of the Day:</h2><p>%s</p></div><div>" "${quote}" >> "${outfile}"
	        else
	            loud "[warn] Fortune command failed (exit code: $quote_exit_code)"
	        fi
	    else
	        loud "[info] Fortune not available or fortune file missing"
	    fi

	    # Add footer
	    cat "${footer_file}" >> "${outfile}"

        # Verify email content is not empty
        email_size=$(stat -c%s "${outfile}" 2>/dev/null || echo "0")
        if [ "$email_size" -lt 100 ]; then
            loud "[ERROR] Generated email is too small ($email_size bytes), skipping send"
            rm -f "${outfile}"
            continue
        fi

		# Email assembled! Send to all recipients
        email_sent_successfully=false
        for email_addy in "${email_addresses[@]}"
	    do
            # Skip empty email addresses (e.g., trailing commas in config)
            [ -n "$email_addy" ] || continue

            loud "[info] Sending email that would have date of ${email_date} to ${email_addy}."
	        (
            echo "From: ${email_from}"
            echo "To: ${email_addy}"
			echo "Date: ${email_date}"
			echo "Subject: Roundup of links for ${short_date}."
			echo "Content-Type: text/html; charset=UTF-8"
			echo "MIME-Version: 1.0";
			echo
			cat "${outfile}"
            ) | /usr/sbin/sendmail -t -f "steven@stevesaus.com"

			if [ "$?" -eq 0 ]; then
				loud "[info] Email sent successfully to ${email_addy}."
				email_sent_successfully=true
			else
				loud "[warn] Sending email failed to ${email_addy}!"
			fi
		done

		# Only mark as sent if at least one email was successful
		if [ "$email_sent_successfully" = true ]; then
		    echo "${base}" >> "${sent_days_db}"
		    files_processed=$((files_processed + 1))
		    loud "[info] Marked ${base} as sent"
		fi

		# Clean up temp file
		rm -f "${outfile}"
	else
	    loud "[info] Skipping file with invalid name pattern: ${base}"
	fi
done

loud "[info] Processing complete. Files processed: $files_processed"

if [ $files_processed -eq 0 ]; then
    loud "[info] No files were processed. Possible reasons:"
    loud "  - All files are for today's date"
    loud "  - All files have already been sent"
    loud "  - No files match YYYYMMDD.md pattern"
    loud "  - All source files are empty"
fi
