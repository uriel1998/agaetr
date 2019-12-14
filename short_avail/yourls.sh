#!/bin/bash

function yourls_shortener {
 
yourls_api=$(grep yourls_api "$HOME/.config/rss_social/rss_social.ini" | sed 's/ //g'| awk -F '=' '{print $2}')
yourls_site=$(grep yourls_site "$HOME/.config/rss_social/rss_social.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
yourls_string=$(printf "%s/yourls-api.php?signature=%s&action=shorturl&format=simple&url=%s -O- --quiet" "$yourls_site" "$yourls_api" "$url")

short_url=$(wget "$yourls_string")  

}
