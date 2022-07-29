#!/bin/bash

function shaarli_send {
    
    binary=$(grep 'shaarli =' "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    #outstring=$(printf "From %s: %s - %s %s %s" "$pubtime" "$title" "$description" "$link" "$hashtags")

    # No length requirements here!
    tags=$(echo "$hashtags"  | sed 's|#||g' )
    # NEED TO ADD CONFIG FILE EXPLICITLY HERE
    outstring=$(echo "$binary post-link --description \"$description\" --tags \"$tags\" --title \"$title\" --url $link ")

    eval ${outstring} > /dev/null
}

