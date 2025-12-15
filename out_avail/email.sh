#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

# USING CURL credit
#https://blog.edmdesigner.com/send-email-from-linux-command-line/

function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
			echo "$@" 1>&2
}

# should have been passed in, but just in case...

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"

function email_send {
    if [ -z "${1}" ];then
        title="Automated email from agaetr: ${link}"
    else
        title="${1}"
    fi
    smtp_server=$(grep 'smtp_server =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    smtp_port=$(grep 'smtp_port =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    smtp_username=$(grep 'smtp_username =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    smtp_password=$(grep 'smtp_password =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    email_from=$(grep 'email_from =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    raw_emails=$(grep 'email_to =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')

    tmpfile=$(mktemp)
    loud "Obtaining text of HTML..."
    echo "${link}" > ${tmpfile}
    echo "  " >> ${tmpfile}

    # We have MUCH better ways of getting this email.
    local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"
    input=$(wget --no-check-certificate -erobots=off --user-agent="${ua}" -O- "${link}" )

    antimatch=""
    antimatch=$(echo "${input}" | pup 'div[style*="display: none;"],div[style*="display:none;"], div[style*="visibility: hidden;"], div[style*="overflow: hidden;"]')
    echo " " # <- leading whitespace, do not delete
    lynx_vars=""
    if [ "$antimatch" != "" ];then
        echo "${input}"  | pup | grep -vF "${antimatch}" | sed -e 's/<div[^>]*>//g' | sed 's/<img[^>]\+>//g' | sed -e 's/<!-- -->//g'| sed -e 's/<em[^>]*>/§⬞/g' | sed -e 's/<\/em>/⬞§/g' | sed -e 's/<strong[^>]*>/§⬞/g' | sed -e 's/<\/strong>/⬞§/g' | sed -e 's/<\/tr>/<\/tr><br \/>/g'| lynx -dump -stdin -assume_charset=UTF-8 -force_empty_hrefless_a -hiddenlinks=ignore -html5_charsets -dont_wrap_pre -width=$WRAP -collapse_br_tags | grep -v "READ MORE:" >> ${tmpfile}
    else
        echo "${input}"  | pup | sed -e 's/<div[^>]*>//g' | sed 's/<img[^>]\+>//g' | sed -e 's/<!-- -->//g'| sed -e 's/<em[^>]*>/§⬞/g' | sed -e 's/<\/em>/⬞§/g' | sed -e 's/<strong[^>]*>/§⬞/g' | sed -e 's/<\/strong>/⬞§/g' | sed -e 's/<\/tr>/<\/tr><br \/>/g'| lynx -dump -stdin -assume_charset=UTF-8 -force_empty_hrefless_a -hiddenlinks=ignore -html5_charsets -dont_wrap_pre -width=$WRAP -collapse_br_tags | grep -v "READ MORE:" >> ${tmpfile}
    fi


    # Split raw CSV of of emails into actual email addresses
    OIFS="$IFS"
    IFS=';' read -ra email_addresses <<< "${raw_emails}"
    IFS="$OIFS"
    curl_bin=$(which curl)
    for email_addy in ${email_addresses[@]}
    do
        # assemble the header
        loud "Assembling the header"
        tmpfile2=$(mktemp)
        echo "To: ${email_addy}" > "${tmpfile2}"
        echo "Subject: ${title}" >> "${tmpfile2}"
        echo "From: ${email_from}" >> "${tmpfile2}"
        echo -e "\n\n" >> "${tmpfile2}"
        cat "${tmpfile}" >> "${tmpfile2}"
        # assemble the command
        loud "Assembling the command for $email_addy."
        command_line=$(printf "%s --url \'smtps://%s:%s\' --ssl-reqd --mail-from \'%s\' --mail-rcpt \'%s\' --upload-file %s --user \'%s:%s\'"
        "${curl_bin}" "${smtp_server}" "${smtp_port}" "${email_from}" "${email_addy}" "${tmpfile2}" "${smtp_username}" "${smtp_password}")
        eval "${command_line}";poster_result_code=$?     # returns 0|1
        rm "${tmpfile2}"
    done
    rm ${tmpfile}
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
        email_send "${title}"
    fi
fi
