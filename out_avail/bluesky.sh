#!/usr/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
##############################################################################

#export BSKYSHCLI_SELFHOSTED_DOMAIN= ##
#PATH=$PATH:/home/steven/.local/bsky_sh_cli/bin
#export PATH
#source /home/steven/.bsky_sh_cli.rc
#/home/steven/.local/bsky_sh_cli/bin/bsky login --handle ### --password #



#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=0

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


function bluesky_send {

    if [ "$title" == "$link" ];then
        title=""
    fi
    

    
    binary=$(grep 'bluesky =' "/home/steven/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    outstring=$(printf "(%s) %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")


    if [ ${#outstring} -gt 300 ]; then
        outstring=$(printf "(%s) %s - %s %s" "$pubtime" "$title" "$description" "$link")
        if [ ${#outstring} -gt 300 ]; then
            outstring=$(printf "%s - %s %s %s" "$title" "$description" "$link")
            if [ ${#outstring} -gt 300 ]; then
                outstring=$(printf "(%s) %s %s " "$pubtime" "$title" "$link")
                if [ ${#outstring} -gt 300 ]; then
                    outstring=$(printf "%s %s" "$title" "$link")
                    if [ ${#outstring} -gt 300 ]; then
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
        Limgurl=$(echo "--image ${Outfile} --alt \'An automated image pulled from the post\'")
    else
        Limgurl=""
    fi

    
    
    postme=$(printf "%s post --text \'%s\' %s %s" "${binary}" "${outstring}" "${Limgurl}")
    echo "${postme}"
    eval ${postme}
    
    if [ -f "$Outfile" ];then
        rm "$Outfile"
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
        toot_send
    fi
fi
