#!/bin/bash

##############################################################################
#
#  shortening script
#  (c) Steven Saus 2020
#  Licensed under the MIT license
#
##############################################################################

function murl_shortener {
 
murl_string=$(printf "https://murl.com/api.php?url=%s" "$url")
shorturl=$(curl -s "$murl_string")  
echo "$shorturl"
}
