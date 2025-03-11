#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

LOUD=1

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function pixelfed_send {
    
    if [ "$title" == "$link" ];then
        title=""
    fi
    
    if [ ${#link} -gt 36 ]; then 
        # finding shortener, install directory
        # if not set by the calling script
        if [ -z "$INSTALL_DIR" ];then
            # This should be in a subdirectory of agaetr. As should the shorteners.
            # Get the parent directory of the current directory
            INSTALL_DIR="$(cd .. && pwd)"
        fi
        if [ -f "${INSTALL_DIR}/short_enabled/yourls.sh" ];then
            source "${INSTALL_DIR}/yourls.sh"
            loud "Sending to shortener function"
            yourls_shortener
        fi
    fi
    
    binary=$(grep 'toot =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    account_using=$(grep 'pixelfed =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    
    if [ "${account_using}" == "" ];then
        loud "No pixelfed account specified"
        exit 98
    fi
    
    
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

    loud "${imgurl}" 
    loud "${ALT_TEXT}"
    
    # Get the image, if exists, then send the post
    if [ ! -z "${imgurl}" ];then
        if [ -f "${imgurl}" ];then
            Outfile="${imgurl}"
        else
            Outfile=$(mktemp)
            curl "${imgurl}" -o "${Outfile}" --max-time 60 --create-dirs -s
        fi
        if [ -f "${Outfile}" ];then
            loud "Image obtained, resizing."       
            if [ -f /usr/bin/convert ];then
                /usr/bin/convert -resize 1024x1024 "${Outfile}" "${Outfile}" 
            fi
            
            
            #########THIS ESCAPING IS NOT WORKING FOR TOOT.  HM. 
            
            
            if [ ! -z "${ALT_TEXT}" ];then
                Limgurl=$(printf " --media %s --description \"%s\"" "${Outfile}" "${ALT_TEXT}")
            else
                Limgurl=$(printf " --media %s --description \"An image pulled automatically from the post for decorative purposes only.\"" "${Outfile}")
            fi                        
        else
            Limgurl=""
        fi
    else
        Limgurl=""
    fi

    if [ ! -z "${cw}" ];then
        #there should be commas in the cw! apply sensitive tag if there's an image
        if [ ! -z "${imgurl}" ];then
            #if there is an image, and it's a CW'd post, the image should be sensitive
            cw=$(echo "--sensitive -p \"$cw\"")
        else
            cw=$(echo "-p \"$cw\"")
        fi
    else
        cw=""
    fi
 
    if [ "$Limgurl" != "" ];then
        postme=$(printf "%s post \"%s\" %s %s -u %s" "$binary" "${outstring}" "${Limgurl}" "${cw}" "${account_using}")
        eval ${postme}
    else
        loud "No image, not posting to pixelfed."
    fi
    
    if [ -f "${Outfile}" ];then
        rm "${Outfile}"
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
    echo "[info] Function pixelfed ready to go."
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
        pixelfed_send
    fi
fi
