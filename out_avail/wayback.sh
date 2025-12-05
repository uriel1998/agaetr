#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2022
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

function wayback_send {
	LOUD=1
    local wayback_access wayback_secret
    local save_resp job_id
    local status_resp status ts orig
    local archive_url
    local retries=0
	local max_retries=90   # ~3 minutes if sleep 2s per poll; adjust to taste

    # Read keys from your config (same as before)
    wayback_access=$(grep wayback_access "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    wayback_secret=$(grep wayback_secret "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

    if [ -z "${wayback_access}" ] || [ -z "${wayback_secret}" ]; then
        loud "[error] Missing wayback_access or wayback_secret in agaetr.ini"
        return 1
    fi

    if [ -z "${link}" ]; then
        loud "[error] link variable is empty; nothing to archive."
        return 1
    fi

    # 1) Submit the URL to SavePageNow with LOW auth, ask for JSON back
    save_resp=$(curl -sS -X POST "https://web.archive.org/save" \
        -H "Accept: application/json" \
        -H "Authorization: LOW ${wayback_access}:${wayback_secret}" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "url=${link}")

    if [ $? -ne 0 ] || [ -z "${save_resp}" ]; then
        loud "[error] Failed to submit URL to Internet Archive."
        return 1
    fi

    # Extract job_id from JSON without requiring jq
    job_id=$(printf '%s\n' "${save_resp}" | sed -n 's/.*"job_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "${job_id}" ]; then
        loud "[error] Could not parse job_id from response:"
        loud "${save_resp}"
        return 1
    fi

    loud "[info] Submitted to Internet Archive, job_id=${job_id}. Waiting for completion..."

    # 2) Poll the job status until it completes or times out
    while :; do
        status_resp=$(curl -sS -X GET "https://web.archive.org/save/status/${job_id}?timestamp=$(date +%s)" \
            -H "Accept: application/json" \
            -H "Authorization: LOW ${wayback_access}:${wayback_secret}")

        if [ $? -ne 0 ] || [ -z "${status_resp}" ]; then
            loud "[error] Failed to query job status."
            return 1
        fi

        status=$(printf '%s\n' "${status_resp}" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        # Success path: build final archive URL and echo it
        if [ "${status}" = "success" ]; then
            ts=$(printf '%s\n' "${status_resp}" | sed -n 's/.*"timestamp"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            orig=$(printf '%s\n' "${status_resp}" | sed -n 's/.*"original_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

            if [ -z "${ts}" ] || [ -z "${orig}" ]; then
                loud "[error] Job completed but could not parse timestamp/original_url."
                loud "${status_resp}"
                return 1
            fi

            archive_url="https://web.archive.org/web/${ts}/${orig}"
            loud "[info] Archive completed: ${archive_url}"

            # This is the “return value” of the function
            echo "${archive_url}"
            return 0
        fi

        # Explicit failure states (values seen in the wild include "error")
        if [ "${status}" = "error" ] || [ "${status}" = "failed" ]; then
            loud "[error] Archive job failed. Full status JSON follows:"
            loud "${status_resp}"
            return 1
        fi

        # Still pending; wait and try again
        retries=$((retries + 1))
        if [ "${retries}" -ge "${max_retries}" ]; then
            loud "[error] Giving up after ${max_retries} attempts. Last status JSON:"
            loud "${status_resp}"
            return 1
        fi

        sleep 2
    done
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
