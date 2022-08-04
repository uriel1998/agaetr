#!/bin/bash

INI_URL=""

if [ -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
    INI_URL="${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    else
    if [ -f ${XDG_CONFIG_HOME}/agaetr/agaetr.ini ];then
        INI_URL="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
fi

if [ "${INI_URL}" == "" ];then
    # not running
    exit 90
else


    # Search ini file in XDG_CONFIG_HOME
    # find src/cmd/url trio
    # get commands for those feeds
    # use url for output directories
    # then do this - printf if I have to in order for escapes to work
    # wget -O- "${src}" | "${cmd}" > "${url}"
    
    # To clean up and standardize some odd RSS elements from (in my case) from 
    # Wordpress and from TT-RSS.  Also included as examples.

    # summary remove <div class="more-link-wrapper"> until</description>
    #wget -O- "https://ideatrash.net/feed" | sed -e 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g' > $XDG_DATA_HOME/agaetr/feeds/ideatrash_parsed.xml

    # <updated> -> <pubDate> (and closing tags)
    wget -O- "https://my.ttrss.install/public.php?op=rss&id=-2&view-mode=all_articles&key=8293847903" | sed 's@<updated>@<pubDate>@g' | sed 's@</updated>@</pubDate>@g' | sed 's@Media playback is unsupported on your device @@g' > $XDG_DATA_HOME/agaetr/feeds/ttrss_parsed.xml
fi
