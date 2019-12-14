#!/bin/bash

function murl_shortener {
 
murl_string=$(printf "https://murl.com/api.php?%s" "$url")
short_url=$(curl "$murl_string")  

}
