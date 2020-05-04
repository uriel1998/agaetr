#!/bin/bash

#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ ! -f "$HOME/.config/agaetr/agaetr.ini" ];then
    echo "INI not located; betcha nothing else is set up."
    exit 89
fi



#So here we need to get
# 1. today's date and time
# 2. String to send (title)
# 3. Image (if any) to send
# 4. imgalt - from local image? Maybe skip that for the moment
# 5. CWs if any
# Perhaps read from image metadata?
# ADDTL
# Gotta do this so that the other submodules work just fine
# Parse out link from string (if any exist)
# parse out tags from string (if any exist)

#ADDITIONAL:  Should this go in the "buffer" or out immediately?
# And if you want to put it in "buffer", you can do so by adding it to the posts.db section


#20181227091253|Bash shell find out if a variable has NULL value OR not|https://www.cyberciti.biz/faq/bash-shell-find-out-if-a-variable-has-null-value-or-not/||None|None|#bash shell #freebsd #korn shell scripting #ksh shell #linux #unix #bash shell scripting #linux shell scripting #shell script


OIFS=$IFS
IFS='|'
myarr=($(echo "$instring"))
IFS=$OIFS
#pulling array into named variables so they work with sourced functions

# passing published time (from dd MMM)
posttime=$(echo "${myarr[0]}")
posttime2=${posttime::-6}
pubtime=$(date -d"$posttime2" +%d\ %b)
title=$(echo "${myarr[1]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
link=$(echo "${myarr[2]}")
cw=$(echo "${myarr[3]}")
imgurl=$(echo "${myarr[5]}")
imgalt=$(echo "${myarr[4]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
hashtags=$(echo "${myarr[6]}")
description=$(echo "${myarr[7]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )





This would be useful for just posting or for perhaps newsboat, etc

while getopts "k:t:l:c:i:a:b:d:" opt; do
    case $opt in
        k)  pubtime=$(echo "$OPTARG")
            ;;
        t)  title=$(echo "$OPTARG")
            ;;
        l)  link=$(echo "$OPTARG")
            ;;
        c)  cw=$(echo "$OPTARG")
            ;;
        i)  imgurl=$(echo "$OPTARG")
            ;;
        a)  imgalt=$(echo "$OPTARG")
            ;;
        b)  hashtags=$(echo "$OPTARG")
            ;;
        d)  description=$(echo "$OPTARG")
            ;;
        h)  show_help
            exit
            ;;        
    esac
done
shift $((OPTIND -1))


# if run standalone
# and only if run standalone
# run through urlshortener

#if urlshortener - then use urlshortener
# Requires a slightly modified version of 
# https://gist.github.com/uriel1998/3310028
# which only returns the shortened URL.
#shorturl=`bitly.py "$url"`

oysttytter_send
# NOW do function

# passing published day and month
#-k "pubtime" -t "title" -l "link" -c "CW" -i "imgurl" -a "imgalt" -b "hashtags" -d "description"
#time | title | link | CW,tag | imgalt | imgurl | hash,tags | description


# String whole thing together (twitter, so no CW - can we make one?)
