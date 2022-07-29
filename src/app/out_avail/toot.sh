#!/bin/bash

function toot_send {

    binary=$(grep 'toot =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    outstring=$(printf "From %s: %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")

    #Yes, I know the URL length doesn't actually count against it.  Just 
    #reusing code here.

    if [ ${#outstring} -gt 500 ]; then
        outstring=$(printf "From %s: %s - %s %s" "$pubtime" "$title" "$description" "$link")
        if [ ${#outstring} -gt 500 ]; then
            outstring=$(printf "%s - %s %s %s" "$title" "$description" "$link")
            if [ ${#outstring} -gt 500 ]; then
                outstring=$(printf "From %s: %s %s " "$pubtime" "$title" "$link")
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
        echo "Image obtained, resizing."
        #resize to twitter's size if available
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
    
    postme=$(printf "%s post \"%s\" %s %s --quiet" "$binary" "$outstring" "$Limgurl" "$cw")
    eval ${postme}
    
    
    if [ -f "$Outfile" ];then
        rm "$Outfile"
    fi
}
