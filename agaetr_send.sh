#!/bin/bash

##############################################################################
#  agaetr_send.sh
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

# Set defaults and global variables so they can be passed back and forth
# en masse between functions and sourced scripts

# LOUD=0  <-- this should be set by env

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
inifile=""
SHORTEN=0
IARCHIVE=0
prefix=""
instring=""
posttime=""
posttime2=""
pubtime=""
title=""
link=""
cw=""
imgurl=""
imgalt=""
# compatibility
ALT_TEXT=""
hashtags=""
description=""
# these are for archived links
description2=""
description2_md=""
description2_html=""

##########Functions



function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
	fi
}





function get_instring() {
    if [ ! -s "${XDG_DATA_HOME}/agaetr/posts.db" ];then
        loud "[info] Nothing to post."
        return 1
    fi

    mv "${XDG_DATA_HOME}/agaetr/posts.db" "${XDG_DATA_HOME}/agaetr/posts_back.db"
    tail -n +2 "${XDG_DATA_HOME}/agaetr/posts_back.db" > "${XDG_DATA_HOME}/agaetr/posts.db"
    instring=$(head -1 "${XDG_DATA_HOME}/agaetr/posts_back.db")
    rm "${XDG_DATA_HOME}/agaetr/posts_back.db"


    if [ -z "$instring" ];then
        loud "[info] Nothing to post."
        return 1
    fi

    loud "[info] Adding string to the posted db"
    echo "$instring" >> "${XDG_DATA_HOME}/agaetr/posted.db"

    return 0
}

function parse_instring() {
    local remainder=""

    IFS='|' read -r posttime title link cw imgalt imgurl hashtags description remainder <<< "${instring}"

    # passing published time (from dd MMM)
    posttime2="${posttime::-6}"
    pubtime=$(date -d"$posttime2" +%d\ %b)
    title=$(echo "${title}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    imgalt=$(echo "${imgalt}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    description=$(echo "${description}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
}

function get_better_description() {
    # to strip out crappy descriptions and either omit them or, if available,
    # substitute og tags.
    local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:154.0) Gecko/20100101 Firefox/154.0"

    patterns=("Photo illustration by" "The Independent is on the ground" "Sign up for our email newsletter" "originally published")
    patterns+="(Image Credit:"

    # Loop through the array and check if any pattern matches
    # If so, nuke the description.
    for pattern in "${patterns[@]}"; do
        if [[ "$description" == *"$pattern"* ]]; then
            loud "[info] Removing bogus description."
            description=""
        fi
    done
    loud "[info] Attempting to find OpenGraph tags for description"
    html=$(wget --no-check-certificate -erobots=off --timeout=15 --tries=1 --user-agent="${ua}" -O- "${link}" | sed 's|>|>\n|g' | hxunent -f ) # NOT XML SAFE YET, need -b switch

    og_description=$(echo "${html}" | sed -n 's/.*<meta property="og:description".* content="\([^"]*\)".*/\1/p' | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/❲/g' -e 's/)/❳/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g' | hxunent -f )
    if [[ "$description" == *"..."* ]] && [ "$og_description" != "" ];then
        loud "[info] Subsituting OpenGraph description for parsed description."
        description="${og_description}"
    else
        if [ "$og_description" != "" ] && [ "$description" == "" ];then
            loud "[info] Subsituting OpenGraph description for empty or bad description."
            description="${og_description}"
        else
            # it's the original description, so now need to clean it with hxenunt
            description=$(echo "${description}" | hxunent -f | sed -e 's/ "/ “/g' -e 's/" /” /g' -e 's/"\./”\./g' -e 's/"\,/”\,/g' -e 's/\."/\.”/g' -e 's/\,"/\,”/g' -e 's/"/“/g' -e "s/'/’/g" -e 's/ -- /—/g' -e 's/(/❲/g' -e 's/)/❳/g' -e 's/ — /—/g' -e 's/ - /—/g'  -e 's/ – /—/g' -e 's/ – /—/g' | hxunent -f )
        fi
    fi

}

function check_image() {
    local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:154.0) Gecko/20100101 Firefox/154.0"

    loud "[info] Read in image url: ${imgurl}"
    loud "[info] Read in image alt: ${imgalt}"
    if [[ $imgurl == *missing-image* ]] || [[ $imgurl == *placeholder* ]];then
        imgurl=""
        imgalt=""
    fi
    if [ "${imgalt}" == "alt" ];then
        imgalt=""
    fi

    if [ "${imgurl}" == "None" ];then
        loud "[info] No image stored in db."
        imgurl=""
        imgalt=""
    fi

    if [ "${imgurl}" != "" ];then
        #Checking the stored image url
        loud "[info] Checking existence of ${imgurl}"
        imagecheck=$(wget -q --spider --timeout=15 --tries=1 --no-check-certificate -erobots=off --user-agent="${ua}" "${imgurl}"; echo $?)
        if [ "${imagecheck}" -ne 0 ];then
            loud "[warn] Stored image no longer available."
            imgurl=""
            imgalt=""
        fi
    fi

    if [ "${imgurl}" == "" ];then
        loud "[info] Checking image opengraph tags"
        # adding in looking for opengraph metadata here.
        # Fetch webpage content
        # using wget because some sites (independent, cough) don't return anything
        # with curl?
        html=$(wget --no-check-certificate -erobots=off --timeout=15 --tries=1 --user-agent="${ua}" -O- "${link}" | sed 's|>|>\n|g')
        # Extract og:image content
        og_image=$(echo "${html}" | sed -n 's/.*<meta property="og:image".* content="\([^"]*\)".*/\1/p' | hxunent -f)
        # Extract og:image:alt content
        og_image_alt=$(echo "${html}" | sed -n 's/.*<meta property="og:image:alt".* content="\([^"]*\)".*/\1/p' | hxunent -f  )
        if [[ $og_image == http* ]];then
            imgurl="${og_image}"
            imgalt="${og_image_alt}"
            loud "[info] Found ${og_image}"
            loud "[info] Found ${og_image_alt}"
        else
            loud "[warn] OpenGraph tags not found."
        fi
    fi

    #Checking the image url AGAIN before sending it to the client
    if [ "${imgurl}" != "" ];then
        imagecheck=$(wget -q --spider --timeout=15 --tries=1 --no-check-certificate -erobots=off --user-agent="${ua}" "${imgurl}"; echo $?)
    else
        imagecheck=1
    fi

    if [ "${imgurl}" == "" ];then
        loud "[info] No usable image found."
    elif [ "${imagecheck}" -ne 0 ];then
        loud "[warn] Image no longer available; omitting."
        imgurl=""
        imgalt=""
    else
        loud "[info] Image found, good to go."
        # substituting og:alt if it is empty and not set by user
        if [ "${imgalt}" == "" ] && [ "${ALT_TEXT}" != "" ];then
            imgalt="${ALT_TEXT}"
        fi
        if [ "${imgalt}" != "" ] && [ "${ALT_TEXT}" == "" ];then
            ALT_TEXT="${imgalt}"
        fi
        if [ "${imgalt}" == "" ] && [ "${ALT_TEXT}" == "" ];then
            # this can handle URLs or files passed to it.
			if [ -f "$SCRIPT_DIR/ai_gen_alt_text.sh" ];then
				ALT_TEXT=$("$SCRIPT_DIR/ai_gen_alt_text.sh" "${imgurl}")
				imgalt="${ALT_TEXT}"
			else
                #fallback
				imgalt="An image for decorative purposes automatically pulled from the post."
			fi
            ALT_TEXT="${imgalt}"
        fi
        loud "[info] Using alt text of ${ALT_TEXT}."
    fi
}




##############################################################################
#
# Script Enters Here
#
##############################################################################

## What do we know?

if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [ ! -d "${XDG_CONFIG_HOME}" ];then
    export XDG_CONFIG_HOME="${HOME}/.config"
fi



if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "INI not located. Exiting." >&2
    exit 89
else
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
fi
if [ ! -f "${XDG_DATA_HOME}/agaetr/posts.db" ];then
    echo "Post database not located, exiting." >&2
    exit 99
fi


if [ $(grep 'wayback_access' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}') != "" ];then
    IARCHIVE=1
    ArchiveLinks=$(grep 'ArchiveLinks' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
else
    IARCHIVE=0
    ArchiveLinks=ignore
fi

# Note that it must be BOTH in enabled and the trigger is actually putting the API key in place.
if [ -f "${SCRIPT_DIR}/short_enabled/yourls.sh" ] && [ $(grep 'yourls_api' "${inifile}"  | sed 's/ //g'| awk -F "=" '{print $2}') != "" ];then
    source "${SCRIPT_DIR}/short_enabled/yourls.sh"
    SHORTEN=1
fi

# parse command line options
# This should ONLY be pulling from the database, not directly
while [ $# -gt 0 ]; do
    option="$1"
    case $option in

    --help)
        display_help
        exit
        ;;
    --loud)
        LOUD=1
        shift
        ;;
    *) shift ;;
    esac
done


loud "[info] Getting instring"
if ! get_instring;then
    exit 0
fi
loud "[info] Parsing instring"
parse_instring

# Deshortening, deobfuscating, and unredirecting the URL with muna
original_link="$link"
url="$link"
loud "[info] Running muna"
source "$SCRIPT_DIR/muna.sh"
strip_tracking_url
unredirector
if [ -n "${url}" ];then
    link="$url"
else
    loud "[warn] URL processing returned empty; keeping original link."
    link="$original_link"
fi


loud "[info] Checking image"
check_image
loud "[info] Checking description"
get_better_description

# Dealing with archiving links
description2=""


if [ $IARCHIVE -eq 1 ];then
    loud "[info] Getting Wayback link (this may take literally 1-3 minutes!)"
	# That's right, it's in avail. This is SEPARATE from it being called
	# as an out method, which can ALSO be done on a per call basis
	source "$SCRIPT_DIR/out_avail/wayback.sh"
    # this should now set IARCHIVE to the IARCHIVE url
	IARCHIVE=$(wayback_send)
    # I may need to put in a shortening thing here
    # Making sure we get a URL back
    if [[ $IARCHIVE =~ http* ]];then
        loud "[info] Got Wayback link of ${IARCHIVE} "
        # They are always SUPER long
        if [ $SHORTEN -eq 1 ];then
            loud "[info] Shortening wayback"
            shortlink=$(yourls_shortener "${IARCHIVE}")
            if [[ $shortlink =~ http* ]];then
                loud "[info] Wayback shortened to ${shortlink}"
                IARCHIVE="${shortlink}"
            fi
        fi
        description2="ia: ${IARCHIVE} "
        description2_md="[ia](${IARCHIVE})  "
        description2_html="<a href=\"${IARCHIVE}\">ia</a> "
    else
        loud "[error] Did not get Wayback link"
    fi
fi
if [ -n "${description2}" ];then
    case ${ArchiveLinks} in
        replace*)
            description="${description2}"
            loud "[info] Links archived, replacing description."
            ;;
        append*)
            loud "[info] Links archived, added to description."
            description="${description} ${description2}"
            ;;
		ignore*)
			loud "[info] Link archived, removed from description2"
			description2=""
			;;
        *)  loud "[info] Links archived, not added to description."
            ;;
    esac
else
    loud "[warn] Links not archived."
fi


# SHORTENING OF URL
# Look, if the URL is longer than 64 characters... some of these are 128+
# and I use this with BlueSky as well.
if [ $SHORTEN -eq 1 ] && [ ${#link} -gt 64 ]; then
    loud "[info] Sending URL to shortener function"
    shortlink=$(yourls_shortener "${link}")
    # TODO -- use this with bsky, etc.
    if [[ $shortlink =~ http* ]];then
        export shortlink
    fi
fi

# Parsing enabled out systems. Find files in out_enabled, then import
# functions from each and running them with variables already established.

posters=$(ls -A "$SCRIPT_DIR/out_enabled")

for p in $posters;do
    if [ "$p" != ".keep" ];then
        loud "[info] Processing ${p%.*}..."
        send_funct=$(echo "${p%.*}_send")
        source "${SCRIPT_DIR}/out_enabled/${p}"
        poster_result_code=0
        eval ${send_funct}
		if [ "$poster_result_code" != "0" ];then
            loud "[ERROR] ${p} did not succeed in some way!"
        fi
        sleep 5
    fi
done
