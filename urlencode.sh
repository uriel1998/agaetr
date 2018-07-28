#!/bin/bash

########################################################################
# Url Encode snippet from https://gist.github.com/cdown/1163649
########################################################################

urlencode() {
    # urlencode <string>

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) eval printf '%s' '$c' | xxd -p -c1 |
                   while read c; do printf '%%%s' "$c"; done ;;
        esac
    done
}

urlencode "$1"
