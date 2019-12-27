#!/bin/bash

function murl_shortener {
 
murl_string=$(printf "https://murl.com/api.php?url=%s" "$url")
short_url=$(curl -s "$murl_string")  
echo "$short_url"
}
