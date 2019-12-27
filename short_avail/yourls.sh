#!/bin/bash

function yourls_shortener {
 
yourls_api=$(grep yourls_api "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g'| awk -F '=' '{print $2}')
yourls_site=$(grep yourls_site "$HOME/.config/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
yourls_string=$(printf "%s/yourls-api.php?signature=%s&action=shorturl&format=simple&url=%s" "$yourls_site" "$yourls_api" "$url")
short_url=$(wget "$yourls_string" -O- --quiet)  
echo "$short_url"

}
