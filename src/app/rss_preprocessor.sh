#!/bin/bash

# To clean up and standardize some odd RSS elements from (in my case) from 
# Wordpress and from TT-RSS.  Also included as examples.

# summary remove <div class="more-link-wrapper"> until</description>
wget -O- "https://ideatrash.net/feed" | sed -e 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g' > $XDG_DATA_HOME/agaetr/feeds/ideatrash_parsed.xml

# <updated> -> <pubDate> (and closing tags)
wget -O- "https://my.ttrss.install/public.php?op=rss&id=-2&view-mode=all_articles&key=8293847903" | sed 's@<updated>@<pubDate>@g' | sed 's@</updated>@</pubDate>@g' | sed 's@Media playback is unsupported on your device @@g' > $XDG_DATA_HOME/agaetr/feeds/ttrss_parsed.xml
