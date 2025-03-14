#!/usr/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################
 
LOUD=0

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function tumblr_send {

    if [ "$title" == "$link" ];then
        title=""
    fi
    

    binary=$(grep 'gotumblr =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    textfile=$(grep 'textmd =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    picgo_binary=$(grep 'picgo =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    workdir=$(echo  $( dirname $(realpath "${textfile}") ))
    
    
    #outstring=$(printf "(%s) %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")
   
    # Get the image, if exists. 
    if [ ! -z "${imgurl}" ];then
        # If image is local. upload via picgo
        if [ -f "${imgurl}" ];then
            bob=$(${picgo_binary} u "${imgurl}")
            imgurl=$(echo "${bob}" | grep -e "^http")
        fi    
        # triple check that it's a url
        if [[ $imgurl == http* ]];then
            Limgurl="${imgurl}"
        else
            Limgurl=""
        fi
    fi
    echo "${title}" > "${textfile}"
    if [[ $binary == *gotumblr_ss.go ]]; then
        # This is on purpose with my hacked version of gotumblr
        echo "${hashtags}" >> "${textfile}"
    fi
    echo " " >> "${textfile}"
    echo "${description}" >> "${textfile}"
    echo " " >> "${textfile}"
    printf "<img src=\"%s\">\n" "${Limgurl}" >> "${textfile}"
    echo " " >> "${textfile}"
    if [ "$link" != "" ];then 
        printf "[%s](%s)" "${title}" "${link}" >> "${textfile}"
        echo " " >> "${textfile}"
    fi
   
    
    CURR_DIR=$(pwd)
    cd "${workdir}"
    runstring=$(printf "go run %s/%s t" "${workdir}" "${binary}")
    eval "${runstring}"
    cd "${CURR_DIR}"
    
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
    loud "[info] Function tumblr ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        tumblr_send
    fi
fi
