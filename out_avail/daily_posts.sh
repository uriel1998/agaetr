#!/usr/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################
 
 

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function daily_posts_send {

    if [ "$title" == "$link" ];then
        title=""
    fi
    
    path=$(grep 'daily_posts =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')  
    workdir=$(realpath "${path}") 
    if [ ! -d "${workdir}" ];then
        mkdir -p "${workdir}"
    fi
    textfile="${workdir}/$(date +%Y%m%d).md"
    echo "${textfile}"
    echo "${workdir}"
    if [ ! -f "${textfile}" ];then
        loud "[info] Starting new daily post"
        echo "# Notable and new (to me) links from $(date +"%d %b %Y")  " > "${textfile}"
        echo " " >> "${textfile}"
        echo "***" >> "${textfile}"
    fi
    
    #outstring=$(printf "(%s) %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")
    loud "[info] Adding to daily post"
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
    echo "## ${title}" >> "${textfile}"
    echo " " >> "${textfile}"
    echo "${description}" >> "${textfile}"

    if [ "$Limgurl" != "" ];then 
        if [ "${ALT_TEXT}" != "" ];then
            printf "<img src=\"%s\" alt=\"%s\" >\n" "${Limgurl}" "${ALT_TEXT}" >> "${textfile}"
        else
            printf "<img src=\"%s\" alt=\"A decorative image automatically pulled from the post.\" >\n" "${Limgurl}" >> "${textfile}"
        fi
    fi
    echo " " >> "${textfile}"
    if [ "$link" != "" ];then 
        printf "[%s](%s)" "${title}" "${link}" >> "${textfile}"
        echo " " >> "${textfile}"
    fi
    if [ "$description2_md" != "" ];then
        echo "***" >> "${textfile}"
        echo "### Archive Links:  " >> "${textfile}"
        echo "${description2_md}" >> "${textfile}"
        echo "***" >> "${textfile}"
    fi   
    echo "${hashtags}" >> "${textfile}"
    echo "***" >> "${textfile}"
    loud "[info] Finished adding to daily post"
    
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
        daily_posts_send
    fi
fi
