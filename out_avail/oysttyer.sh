#!/bin/bash

function oysttyer_send {
    
    binary=$(grep 'oysttyer =' "$HOME/.config/rss_social/rss_social.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
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
    outstring=$(echo "$binary -silent -status=$outstring")
    eval ${outstring}
}



