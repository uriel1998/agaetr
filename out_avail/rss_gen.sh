#!/bin/bash

##############################################################################
#
#  Sending helper script for agaetr
#  (c) Steven Saus 2025
#  Licensed under the MIT license
# use as output for bookmark program
# to create RSS feed of items (for publication, agaeter, etc)
#
#https://stackoverflow.com/questions/12827343/linux-send-stdout-of-command-to-an-rss-feed
#
##############################################################################


if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
RSSSavePath=$(grep 'rss_output_path' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
self_link=$(grep 'self_link' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')

function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
	fi
}



function rss_gen_send {

    if [ ! -f "${RSSSavePath}" ];then
        loud "[info] Starting XML file"
        printf '<rss xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" version="2.0">\n' >> "${RSSSavePath}"
        printf '  <channel>\n' >> "${RSSSavePath}"
        printf '    <title>My RSS Feed</title>\n' >> "${RSSSavePath}"
        printf '    <description>This is my RSS Feed</description>\n' >> "${RSSSavePath}"
        printf '    <link>%s</link>\n' "${self_link}" >> "${RSSSavePath}"
        printf '    <atom:link rel="self" href="%s" type="application/rss+xml" />\n' "${self_link}" >> "${RSSSavePath}"
        printf '  </channel>\n' >> "${RSSSavePath}"
        printf '</rss>\n' >> "${RSSSavePath}"
    fi
    picgo_binary=$(grep 'picgo' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    # Get the image, if exists.
    if [ ! -z "${imgurl}" ];then
        # If image is local. upload via picgo
        if [ -f "${imgurl}" ];then
            loud "[info] Image is a local file, uploading via picgo"
            bob=$(${picgo_binary} u "${imgurl}")
            imgurl=$(echo "${bob}" | grep -e "^http")
        fi
        # triple check that it's a url
        if [[ $imgurl == http* ]];then
            loud "[info] Image exists, and is an URL"
            Limgurl="${imgurl}"
        else
            Limgurl=""
        fi
    fi
    XML_title=$(echo "${title}" | hxunent -fb )
    XML_description=$(echo "${description}" | hxunent -fb )
    XML_description2=$(echo "Archive links: ${description2}" | hxunent -fb )


    TITLE="${XML_title}"
    LINK="${link}"
    DATE="$(date -R)"
    DESC=$(printf "%s\n\n%s\n" "${XML_description}" "${XML_description2_html}")
    GUID="${link}"
    #TODO:This is not adding images like it's supposed to, sigh....
    loud "[info] Adding entry to RSS feed"
    if [ -n "${Limgurl//[[:space:]]/}" ]; then
        loud "[info] Media found, inserting."
        # Pass 1: add item and media:content element
        xmlstarlet ed -L -N media="http://search.yahoo.com/mrss/" \
            -i "/rss/channel/*[1]" -t elem -n item -v "" \
            -s "/rss/channel/item[1]" -t elem -n title       -v "${TITLE}" \
            -s "/rss/channel/item[1]" -t elem -n link        -v "${LINK}" \
            -s "/rss/channel/item[1]" -t elem -n pubDate     -v "${DATE}" \
            -s "/rss/channel/item[1]" -t elem -n description -v "${DESC}" \
            -s "/rss/channel/item[1]" -t elem -n guid        -v "${GUID}" \
            -s "/rss/channel/item[1]" -t elem -n "media:content" -v "" \
            -d "/rss/channel/item[position()>10]" \
            "${RSSSavePath}" || return 1

        # Pass 2: set attributes on the (now definitely present) media:content
        xmlstarlet ed -L -N media="http://search.yahoo.com/mrss/" \
            -i "/rss/channel/item[1]/media:content[not(@url)]"    -t attr -n url    -v "${Limgurl}" \
            -i "/rss/channel/item[1]/media:content[not(@medium)]" -t attr -n medium -v "image" \
            -u "/rss/channel/item[1]/media:content/@url"          -v "${Limgurl}" \
            -u "/rss/channel/item[1]/media:content/@medium"       -v "image" \
            "${RSSSavePath}" || return 1
    else
        loud "[info] No media found, writing."
        xmlstarlet ed -L \
    		-i "/rss/channel/*[1]" -t elem -n item -v "" \
    		-s "/rss/channel/item[1]" -t elem -n title       -v "${TITLE}" \
    		-s "/rss/channel/item[1]" -t elem -n link        -v "${LINK}" \
    		-s "/rss/channel/item[1]" -t elem -n pubDate     -v "${DATE}" \
    		-s "/rss/channel/item[1]" -t elem -n description -v "${DESC}" \
    		-s "/rss/channel/item[1]" -t elem -n guid        -v "${GUID}" \
    		-d "/rss/channel/item[position()>10]" \
    		"${RSSSavePath}"
    fi
}


##############################################################################
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
$(return >/dev/null 2>&1)

# What exit code did that give?
if [ "$?" -eq "0" ];then
    echo "[info] Function RSS generator ready to go."
    OUTPUT=0
else
    OUTPUT=1
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        if [ "${1}" == "--loud" ];then
            LOUD=1
            shift
        else
            if [ "$LOUD" == "" ];then
                # so it doesn't clobber exported env
                LOUD=0
            fi
        fi
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        rss_gen_send
    fi
fi
