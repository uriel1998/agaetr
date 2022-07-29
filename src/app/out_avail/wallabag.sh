#!/bin/bash

function wallabag_send {
    
    binary=$(grep 'wallabag =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

    outstring=$(echo "$binary add --quiet --title \"$title\" $link ")
    echo "$outstring"
    eval ${outstring} > /dev/null
}

