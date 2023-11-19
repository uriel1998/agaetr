#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
##############################################################################

# TODO - Adapt for prefix!
# should have been passed in, but just in case...
# Actually, these all should have already been handled, since this is literally
# just a file of functions.
    

################################################################################
# Out Methodologies
################################################################################

# USING CURL credit
#https://blog.edmdesigner.com/send-email-from-linux-command-line/
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
        eval "${command_line}"
        rm "${tmpfile2}"
    done
    rm ${tmpfile}
}

function shaarli_send {
    
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    
    binary=$(grep 'shaarli =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    # No length requirements here!
    tags=$(echo "$hashtags"  | sed 's|#||g' )

    #outstring=$(printf "From %s: %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")

    # Check to loop over multiple configs in ini
    configs=$(grep --after-context=1 "[shaarli_config" "${inifile}" | grep -v -e "[shaarli_config" -e "--")
    # this isn't in quotation marks so we get the newline, fyi.
    for cfile in ${configs}
    do
        if [ ! -f ${cfile} ];then
            # The above is both for backwards compatibility and for continuing even after errors
            if [ -z "${description}" ];
                outstring=$(echo "$binary post-link --title \"$title\" --url $link ")
            else
                outstring=$(echo "$binary post-link --description \"$description\" --tags \"$tags\" --title \"$title\" --url $link ")
            fi
        else
            if [ -z "${description}" ];
                outstring=$(echo "$binary --config ${cfile} post-link --title \"$title\" --url $link ")
            else
                outstring=$(echo "$binary --config ${cfile} post-link --description \"$description\" --tags \"$tags\" --title \"$title\" --url $link ")
            fi
        fi

        eval ${outstring} > /dev/null
    done
}

function save_html_send {

    outdir=$(grep 'html_dir =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ -z "${outdir}" ];then
        outdir="${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -d "${outdir}" ];then
        mkdir -p "${outdir}"
    fi
    if [ -f $(which detox) ];then
        dttitle=$(echo "${title}" | detox --inline)
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${dttitle}-${dstring}"
    else
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${title}-${dstring}"
    fi    
    nowdir=$(echo "${PWD}")
    mkdir -p "${outpath}"
    cd "${outpath}"    
    binary=$(grep 'wget =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which wget)
    fi
    if [ -f "$binary" ];then
        outstring=$(echo "$binary -H --connect-timeout=2 --read-timeout=10 --tries=1 -p -k --convert-links --restrict-file-names=windows -e robots=off \"${link}\"")
        eval "${outstring}"
    fi
    cd "${nowdir}"
}

 
function wayback_send {

    # Get your S3-like keys, following these instructions
    # or at https://archive.org/account/s3.php
    # https://docs.google.com/document/d/1Nsv52MvSjbLb2PCpHlat0gkzw0EvtSgpKHu4mk0MnrA/edit#

    wayback_access=$(grep wayback_access "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    wayback_secret=$(grep wayback_secret "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

    curl -X POST -H "Accept: application/json" -H "Authorization: LOW ${wayback_access}:${wayback_secret}" -d"url=${link}&capture_outlinks=1&capture_screenshot=1&skip_first_archive=1&if_not_archived_within=1d'" https://web.archive.org/save

}


function toot_send {
    
    # TODO - make sure stores, resets toot's active profile on launch

    if [ "$title" == "$link" ];then
        title=""
    fi
    
    if [ ${#link} -gt 36 ]; then 
        loud "Sending to shortener function"
        yourls_shortener
    fi
    
    binary=$(grep 'toot =' "${XDG_CONFIG_HOME}/cw-bot/${prefix}cw-bot.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    outstring=$(printf "(%s) %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")

    #Yes, I know the URL length doesn't actually count against it.  Just 
    #reusing code here.

    if [ ${#outstring} -gt 500 ]; then
        outstring=$(printf "(%s) %s - %s %s" "$pubtime" "$title" "$description" "$link")
        if [ ${#outstring} -gt 500 ]; then
            outstring=$(printf "%s - %s %s %s" "$title" "$description" "$link")
            if [ ${#outstring} -gt 500 ]; then
                outstring=$(printf "(%s) %s %s " "$pubtime" "$title" "$link")
                if [ ${#outstring} -gt 500 ]; then
                    outstring=$(printf "%s %s" "$title" "$link")
                    if [ ${#outstring} -gt 500 ]; then
                        short_title=`echo "$title" | awk '{print substr($0,1,110)}'`
                        outstring=$(printf "%s %s" "$short_title" "$link")
                    fi
                fi
            fi
        fi
    fi

   
    # Get the image, if exists, then send the tweet
    if [ ! -z "$imgurl" ];then
        
        Outfile=$(mktemp)
        curl "$imgurl" -o "$Outfile" --max-time 60 --create-dirs -s
        loud "Image obtained, resizing."       
        if [ -f /usr/bin/convert ];then
            /usr/bin/convert -resize 800x512\! "$Outfile" "$Outfile" 
        fi
        Limgurl=$(echo "--media $Outfile")
    else
        Limgurl=""
    fi

    if [ ! -z "$cw" ];then
        #there should be commas in the cw! apply sensitive tag if there's an image
        if [ ! -z "$imgurl" ];then
            #if there is an image, and it's a CW'd post, the image should be sensitive
            cw=$(echo "--sensitive -p \"$cw\"")
        else
            cw=$(echo "-p \"$cw\"")
        fi
    else
        cw=""
    fi
    
    postme=$(printf "%s post \"%s\" %s %s -u %s --quiet" "$binary" "$outstring" "$Limgurl" "$cw" "$account_using")
    eval ${postme}
    
    if [ -f "$Outfile" ];then
        rm "$Outfile"
    fi
}


function matrix_send () {
    # TODO
    # Need to write setup 
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    
    binary=$(grep 'sendmail_matrix =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which sendmail-to-matrix)
    fi
    if [ -f "$binary" ];then
        mserver=$(grep 'matrix_server =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
        mtoken=$(grep 'matrix_token =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
        mroom=$(grep 'matrix_room =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
        mpreface=$(grep 'matrix_preface =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
        # No length requirements here!
        tags=$(echo "$hashtags"  | sed 's|#||g' )
        if [ ! -z "$imgurl" ];then
            printf "(%s) %s - %s %s %s %s" "$pubtime" "$title" "$description" "$imgurl" "$link" "$hashtags" | "${binary}" --server "${mserver}" --preface "${mpreface}" --room "${mstring}" --token "${mtoken}" 
        else
            printf "(%s) %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags" | "${binary}" --server "${mserver}" --preface "${mpreface}" --room "${mstring}" --token "${mtoken}" 
        fi   
    fi
}



function rss_gen_send {
    
    RSSSavePath=$(grep 'rss_output =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "${RSSSavePath}" ];then
        printf '<?xml version="1.0" encoding="utf-8"?>\n' > "${RSSSavePath}"
        printf '<rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">\n' >> "${RSSSavePath}"
        printf '  <channel>\n' >> "${RSSSavePath}"
        printf '    <title>My RSS Feed</title>\n' >> "${RSSSavePath}"
        printf '    <description>This is my RSS Feed</description>\n' >> "${RSSSavePath}"
        printf '    <link rel="self" href="https://stevesaus.me/output.xml" />\n' >> "${RSSSavePath}"
        printf '  </channel>\n' >> "${RSSSavePath}"
        printf '</rss>\n' >> "${RSSSavePath}"    

    fi
    TITLE="${title}"
    LINK=$(printf "href=\"%s\"" "${link}")
    DATE="`date`"
    DESC="${title}"
    GUID="${link}" 

    xmlstarlet ed -L   -a "//channel" -t elem -n item -v ""  \
         -s "//item[1]" -t elem -n title -v "$TITLE" \
         -s "//item[1]" -t elem -n link -v "$LINK" \
         -s "//item[1]" -t elem -n pubDate -v "$DATE" \
         -s "//item[1]" -t elem -n description -v "$DESC" \
         -s "//item[1]" -t elem -n guid -v "$GUID" \
         -d "//item[position()>10]"  "${RSSSavePath}" ; 
}


function wallabag_send {
    
    binary=$(grep 'wallabag =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which wallabag)
    fi
    outstring=$(echo "$binary add --title \"$title\" $link ")
    #echo "$outstring"
    eval ${outstring} > /dev/null
}



function pdf_capture_send {
    # INCLUDED FOR USE WITH OTHER TOOLS; NOT PART OF AGAETR DUE TO REQUIREMENTS FOR X
    outdir=$(grep 'pdf_dir =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ -z "${outdir}" ];then
        outdir="${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -d "${outdir}" ];then
        mkdir -p "${outdir}"
    fi
    if [ -f $(which detox) ];then
        dttitle=$(echo "${title}" | detox --inline)
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${dttitle}-${dstring}.pdf"
    else
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${title}-${dstring}.pdf"
    fi
    
    binary=$(grep 'cutycapt =' "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which cutycapt)
    fi
    if [ -f "$binary" ];then
        outstring=$(printf "%s" "$link" )
        outstring=$(echo "$binary --smooth --url=\"$outstring\" --out=\"${outpath}\"")
        eval ${outstring}
    fi
}

function jpeg_capture_send {
    # INCLUDED FOR USE WITH OTHER TOOLS; NOT PART OF AGAETR DUE TO REQUIREMENTS FOR X
    outdir=$(grep 'jpg_dir =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ -z "${outdir}" ];then
        outdir="${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -d "${outdir}" ];then
        mkdir -p "${outdir}"
    fi


    if [ -f $(which detox) ];then
        dttitle=$(echo "${title}" | detox --inline)
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${dttitle}-${dstring}.jpg"
    else
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${title}-${dstring}.jpg"
    fi
    
    binary=$(grep 'cutycapt =' "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which cutycapt)
    fi
    if [ -f "$binary" ];then
        outstring=$(printf "%s" "$link" )
        outstring=$(echo "$binary --smooth --insecure --url=\"$outstring\" --out=\"${outpath}\"")
        eval ${outstring}
    fi
}

function png_capture_send {
    # INCLUDED FOR USE WITH OTHER TOOLS; NOT PART OF AGAETR DUE TO REQUIREMENTS FOR X
    outdir=$(grep 'png_dir =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ -z "${outdir}" ];then
        outdir="${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -d "${outdir}" ];then
        mkdir -p "${outdir}"
    fi
    if [ -f $(which detox) ];then
        dttitle=$(echo "${title}" | detox --inline)
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${dttitle}-${dstring}.png"
    else
        dstring=$(date +%Y%m%d-%H%M%S)
        outpath="${outdir}/${title}-${dstring}.png"
    fi
    
    binary=$(grep 'cutycapt =' "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    if [ ! -f "$binary" ];then
        binary=$(which cutycapt)
    fi
    if [ -f "$binary" ];then
        outstring=$(printf "%s" "$link" )
        outstring=$(echo "$binary --smooth --insecure --url=\"$outstring\" --out=\"${outpath}\"")
        eval ${outstring}
    fi
}

