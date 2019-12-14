#!/bin/bash

#get install directory
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ -f "$HOME/.config/agaetr/agaetr.ini" ];then
    echo "INI not located; betcha nothing else is set up."
    exit 89
fi
if [ ! -f "$HOME/.local/share/agaetr/posts.db" ];then
    echo "Post database not located, exiting."
    exit 99
fi

mv "$HOME/.local/share/agaetr/posts.db" "$HOME/.local/share/agaetr/posts_back.db"
tail -n +2 "$HOME/.local/share/agaetr/posts_back.db" > "$HOME/.local/share/agaetr/posts.db"
instring = $(head -1 "$HOME/.local/share/agaetr/posts_back.db")
rm "$HOME/.local/share/agaetr/posts_back.db"

OIFS=$IFS
IFS='|'
myarr=($(echo "$instring"))
IFS=$OIFS

#20181227091253|Bash shell find out if a variable has NULL value OR not|https://www.cyberciti.biz/faq/bash-shell-find-out-if-a-variable-has-null-value-or-not/||None|None|#bash shell #freebsd #korn shell scripting #ksh shell #linux #unix #bash shell scripting #linux shell scripting #shell script

#pulling array into named variables so they work with sourced functions

# passing published time (from dd MMM)
posttime=$(echo "${myarr[1]}")
posttime2=${posttime::-4}
pubtime=$(date -d"$posttime2" +%d\ %b)
title=$(echo "${myarr[2]}")
link=$(echo "${myarr[3]}")
cw=$(echo "${myarr[4]}")
imgurl=$(echo "${myarr[5]}")
imgalt=$(echo "${myarr[6]}")
hashtags=$(echo "${myarr[7]}")
description=$(echo "${myarr[8]}")
            
#Deshortening, deobfuscating, and unredirecting the URL

url="$link"
source "$SCRIPT_DIR/unredirector"
unredirector
link="$url"


# SHORTENING OF URL
# call first (should be only) element in shortener dir to shorten url

if [ "$(ls -A "$SCRIPT_DIR/short_enabled")" ]; then
    shortener=$(ls -lR "$SCRIPT_DIR/short_enabled" | grep ^l | awk '{print $9}')
    short_funct=$(echo "${shortener%.*}_shortener")
    source "$SCRIPT_DIR/short_enabled/$shortener"
    url="$link"
    eval ${short_funct}
    link="$shorturl"
fi
    
# Parsing enabled out systems. Find files in out_enabled, then import 
# functions from each and running them with variables already established.

posters=$(ls -A "$SCRIPT_DIR/out_enabled")

for p in $posters;do
    echo "Processing ${p%.*}..."
    send_funct=$(echo "${p%.*}_send")
    source "$SCRIPT_DIR/out_enabled/$p"
    eval ${send_funct}
done



