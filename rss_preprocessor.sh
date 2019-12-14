#!bin/bash

# To clean up and standardize some odd RSS elements from (in my case) from 
# Wordpress and from TT-RSS.  Also included as examples.



# summary remove <div class="more-link-wrapper"> until</description>
wget -O- "https://ideatrash.net/feed" | sed -e 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g' > ideatrash.xml



# <updated> -> <pubDate> (and closing tags)
wget -O- "https://rss.stevesaus.me/public.php?op=rss&id=-2&view-mode=all_articles&key=rm01wf5c168527bdf11" | sed 's@<updated>@<pubDate>@g' | sed 's@</updated>@</pubDate>@g' > ttrss.xml
