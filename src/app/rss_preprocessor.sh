#!/bin/bash

INI_URL=""

if [ -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
    INI_URL="${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    else
    if [ -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
        INI_URL="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
fi

echo "${INI_URL}"
if [ ! -f "${INI_URL}" ];then
    # not running
    exit 90
else

    # TODO - THIS RIGHT HERE
    # Search ini file in XDG_CONFIG_HOME
    OIFS=$IFS
    IFS=$'\n'
    myarr=($(grep --after-context=2 -e "^src =" "${INI_URL}"))
    IFS=$OIFS
    # find src/cmd/url trio
    # get commands for those feeds
    # use url for output directories
    # then do this - printf if I have to in order for escapes to work
    len=${#myarr[@]}
    for (( i=0; i<$len; i=$(( i+2 )) )); do         
        if [[ "${myarr[$i]}" != "--" ]];then
            mysrc=""
            mycmd=""
            myurl=""
            thecommand=""
            j=$(( i+1 ))
            k=$(( j+1 ))
            if [[ "${myarr[$i]}" == "src"* ]];then
                mysrc=$(echo "${myarr[$i]}" | awk -F ' = ' '{print $2}')
                if [[ "${myarr[$j]}" == "cmd"* ]];then
                    mycmd=$(echo "${myarr[$j]}" | awk -F ' = ' '{print $2}')
                    if [[ "${myarr[$k]}" == "url"* ]];then
                        myurl=$(echo "${myarr[$k]}" | awk -F ' = ' '{print $2}')
                        
                        #time to create the command string
                        thecommand=$(printf "wget -O- \"%s\" | %s > \"%s/agaetr%s\"" "${mysrc}" "${mycmd}" "${XDG_DATA_HOME}" "${myurl}")
                        # wget -O- "${src}" | "${cmd}" > "${url}"
                        
                        # CHECK FOR PATH OF where it writes to!
                        
                        echo "${thecommand}"
                        #eval "${thecommand}"
                    fi
                fi
            fi
        fi
    done
    
    # To clean up and standardize some odd RSS elements from (in my case) from 
    # Wordpress and from TT-RSS.  Also included as examples.

    # summary remove <div class="more-link-wrapper"> until</description>
    #wget -O- "https://ideatrash.net/feed" | sed -e 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g' > $XDG_DATA_HOME/agaetr/feeds/ideatrash_parsed.xml

    # <updated> -> <pubDate> (and closing tags)
    # wget -O- "https://my.ttrss.install/public.php?op=rss&id=-2&view-mode=all_articles&key=8293847903" | sed 's@<updated>@<pubDate>@g' | sed 's@</updated>@</pubDate>@g' | sed 's@Media playback is unsupported on your device @@g' > $XDG_DATA_HOME/agaetr/feeds/ttrss_parsed.xml
fi
