#!/bin/bash

function twython_send {
    
    binary=$(grep 'twython =' "$HOME/.config/rss_social/rss_social.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    outstring = printf "From %s: %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags"

    if [ ${#outstring} -gt 280 ]; then
        outstring = printf "From %s: %s - %s %s" "$pubtime" "$title" "$description" "$link" 
        if [ ${#outstring} -gt 280 ]; then
            outstring = printf "%s - %s %s %s" "$title" "$description" "$link" 
            if [ ${#outstring} -gt 280 ]; then
                outstring = printf "From %s: %s %s " "$pubtime" "$title" "$link" 
                if [ ${#outstring} -gt 280 ]; then
                    outstring = printf "%s %s" "$title" "$link" 
                    if [ ${#outstring} -gt 280 ]; then
                        short_title=`echo "$title" | awk '{print substr($0,1,110)}'`
                        outstring = printf "%s %s" "$short_title" "$link" 
                    fi
                fi
            fi
        fi
    fi

    # Get the image, if exists, then send the tweet
    if [ ! -z "$imgurl" ];then
    
        Outfile=$(mktemp)
        urlstring=$(echo "$imgurl -o $Outfile --max-time 60 --create-dirs -s")
        curl "$urlstring"
        #resize to twitter's size if available
        if [ -f /usr/bin/convert ];then
            /usr/bin/convert -resize 800x512\! "$Outfile" "$Outfile" 
        fi
        imgurl=$(echo "--file $Outfile")
    else
        imgurl=""
    fi
    
    postme = printf "%s --message %s %s" "$binary" "$outstring" "$imgurl" 
    eval ${postme}

    if [ -f "$Outfile" ];then
        rm "$Outfile"
    fi
}

