#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
##############################################################################

# TODO - REWRITE TO USE CURL
#https://blog.edmdesigner.com/send-email-from-linux-command-line/

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}

# should have been passed in, but just in case...
    
if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini" 

function email_send {
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
    #wget --connect-timeout=2 --read-timeout=10 --tries=1 -e robots=off -O - "${link}" | pandoc --from=html --to=gfm >> ${tmpfile}
    
    wget --connect-timeout=2 --read-timeout=10 --tries=1 -e robots=off -O - "${link}" | sed -e 's/<img[^>]*>//g' | sed -e 's/<div[^>]*>//g' | hxclean | hxnormalize -e -L -s 2>/dev/null | tidy -quiet -omit -clean 2>/dev/null | hxunent | iconv -t utf-8//TRANSLIT - | sed -e 's/\(<em>\|<i>\|<\/em>\|<\/i>\)/&🞵/g' | sed -e 's/\(<strong>\|<b>\|<\/strong>\|<\/b>\)/&🞶/g' |lynx -dump -stdin -display_charset UTF-8 -width 140 | sed -e 's/\*/•/g' | sed -e 's/Θ/🞵/g' | sed -e 's/Φ/🞯/g' >> ${tmpfile}
    
    # Removed addressbook bit since that doesn't make sense here.

    # Split raw CSV of of emails into actual email addresses
    OIFS="$IFS"
    IFS=';' read -ra email_addresses <<< "${raw_emails}"
    IFS="$OIFS"
    curl_bin=$(which curl)
    for email_addy in "${email_addresses[@]}"
    do
        # assemble the header
        loud "Assembling the header"
        
        
        
        # assemble the command 
        loud "Assembling the command for $email_addy."
        command_line=$(printf "%s --url \'smtps://%s:%s\' --ssl-reqd --mail-from \'%s\' --mail-rcpt \'%s\' --user \'%s:%s\'"
        "${curl_bin}" "${smtp_server}" "${smtp_port}" "${email_from}" "${email_addy}" "${smtp_username}" "${smtp_password}")
        eval "${command_line}"
    done


    #curl --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
  --mail-from 'developer@gmail.com' --mail-rcpt 'edm-user@niceperson.com' \
  --upload-file mail.txt --user 'developer@gmail.com:your-accout-password'


    binary=$(grep 'mutt =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which mutt)
    fi
    if [ -f "$binary" ];then
        echo "Sending email..."
        echo ${tmpfile} | mutt -s "${title}" "${email}"
    else
        echo "Mutt not found in order to send email!"
    fi

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
        fi
        email_send
    fi
fi


