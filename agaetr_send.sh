#!/bin/bash

##############################################################################
#  agaetr_send.sh
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################

# Set defaults and global variables so they can be passed back and forth 
# en masse between functions and sourced scripts

export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
SHORTEN=0
ARCHIVEIS=0
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
# compatability
ALT_TEXT=""
hashtags=""
description=""
LOUD=0


## What do we know?


if [ ! -d "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
fi
if [ ! -d "${XDG_CONFIG_HOME}" ];then
    export XDG_CONFIG_HOME="${HOME}/.config"
fi


if [ -f "${SCRIPT_DIR}/short_enabled/yourls.sh" ];then
    source "${SCRIPT_DIR}/yourls.sh"
    SHORTEN=1
fi


if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "ERROR - INI NOT FOUND" >&2
    exit 99
else
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    if [ -f $(grep 'archiveis =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}') ];then 
        ARCHIVEIS=1
    fi
    if [ -f $(grep 'waybackpy =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}') ];then
        IARCHIVE=1
    fi
    if [ $IARCHIVE -eq 1 ] || [ $ARCHIVEIS -eq 1 ];then
        ArchiveLinks=$(grep 'ArchiveLinks =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')
    else
        ArchiveLinks=ignore
    fi
fi



##########Functions


function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}




function get_instring() {

    mv "${XDG_DATA_HOME}/agaetr/${prefix}posts.db" "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db"
    tail -n +2 "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db" > "${XDG_DATA_HOME}/agaetr/${prefix}posts.db"
    instring=$(head -1 "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db")
    rm "${XDG_DATA_HOME}/agaetr/${prefix}posts_back.db"


    if [ -z "$instring" ];then 
        loud "[info] Nothing to post."
        exit
    fi

    loud "[info] Adding string to the posted db"
    echo "$instring" >> "${XDG_DATA_HOME}/agaetr/${prefix}posted.db"
    
}

function parse_instring() {
    OIFS=$IFS
    IFS='|'
    myarr=($(echo "$instring"))
    IFS=$OIFS

    # pulling array into named variables so they work with sourced functions
    # these are all set as global variables so they can be sent to sourced functions

    # passing published time (from dd MMM)
    posttime=$(echo "${myarr[0]}")
    posttime2="${posttime::-6}"
    pubtime=$(date -d"$posttime2" +%d\ %b)
    title=$(echo "${myarr[1]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    link=$(echo "${myarr[2]}")
    cw=$(echo "${myarr[3]}")
    imgurl=$(echo "${myarr[5]}")
    imgalt=$(echo "${myarr[4]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
    hashtags=$(echo "${myarr[6]}")
    description=$(echo "${myarr[7]}" | sed 's|["]|“|g' | sed 's|['\'']|’|g' )
}

function check_image() {
    loud "[info] Read in image url: ${imgurl}"
    loud "[info] Read in image alt: ${imgalt}"
    
    if [ "${imgurl}" == "None" ];then 
        loud "[info] No image stored in db."
        imgurl=""
        imgalt=""
    fi
    
    if [ "${imgurl}" != "" ];then
        #Checking the stored image url 
        loud "[info] Checking existence of ${imgurl}"
        imagecheck=$(wget -q --spider "${imgurl}"; echo $?)
        if [ "${imagecheck}" -ne 0 ];then
            loud "[warn] Stored image no longer available."
            imgurl=""
            imgalt=""
        fi
    fi

    if [ "${imgurl}" == "" ];then
        loud "[info] Checking image opengraph tags"
        # adding in looking for opengraph metadata here, yes, preferentially so.
        # Fetch webpage content
        html=$(curl -s "${link}")
        # Extract og:image content
        og_image=$(echo "${html}" | sed -n 's/.*<meta property="og:image" content="\([^"]*\)".*/\1/p')
        # Extract og:image:alt content
        og_image_alt=$(echo "${html}" | sed -n 's/.*<meta property="og:image:alt" content="\([^"]*\)".*/\1/p')
        if [[ $og_image == http* ]];then
            imgurl="${og_image}"
            imgalt="${og_image_alt}"
            ALT_TEXT="${og_image_alt}"
            loud "[info] Found ${og_image}"
            loud "[info] Found ${og_image_alt}"
        else
            loud "[warn] OpenGraph tags not found."
        fi
    fi
    
    #Checking the image url AGAIN before sending it to the client
    imagecheck=$(wget -q --spider "${imgurl}"; echo $?)

    if [ "${imagecheck}" -ne 0 ];then
        loud "[warn] Image no longer available; omitting."
        imgurl=""
        imgalt=""
    else
        loud "[info] Image found, good to go."
        ALT_TEXT="${imgalt}"
        loud "[info] Found alt text of ${ALT_TEXT}."

    fi
}

 


##############################################################################
# 
# Script Enters Here
# 
##############################################################################

# parse command line options
#
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
    esac
done

if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
    echo "INI not located. Exiting." >&2
    exit 89
fi
if [ ! -f "${XDG_DATA_HOME}/agaetr/posts.db" ];then
    echo "Post database not located, exiting." >&2
    exit 99
fi

loud "[info] Getting instring"
get_instring
loud "[info] Parsing instring"
parse_instring
loud "[info] Checking image"
check_image


# Deshortening, deobfuscating, and unredirecting the URL with muna
url="$link"
loud "[info] Running muna"
source "$SCRIPT_DIR/muna.sh"
unredirector
link="$url"


# Dealing with archiving links
description2=""
if [ $ARCHIVEIS -eq 1 ];then 
    source "$SCRIPT_DIR/archivers/archiveis.sh"
    loud "[info] Getting archive.is link"
    # this should now set ARCHIVEIS to the Archiveis url
    ARCHIVEIS=$(archiveis_send)
    # Making sure we get a URL back
    if [[ $ARCHIVEIS =~ http* ]];then
        loud "[info] Got archive.is link of ${ARCHIVEIS} "
        description2=" ais: ${ARCHIVEIS}"
    else
        loud "[error] Did not get archive.is link"
    fi
fi

if [ $IARCHIVE -eq 1 ];then
    loud "[info] Getting Wayback link (this may take a moment!)"
    source "$SCRIPT_DIR/archivers/wayback.sh"
    # this should now set IARCHIVE to the IARCHIVE url
    IARCHIVE=$(wayback_send)
    # I may need to put in a shortening thing here
    # Making sure we get a URL back
    echo "$IARCHIVE"
    if [[ $IARCHIVE =~ http* ]];then
        loud "[info] Got Wayback link of ${IARCHIVE} "
        description2="${description2} ia: ${IARCHIVE} "
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
        *)  loud "Links archived, not added to description."
            ;;
    esac
else
    loud "[warn] Links not archived."
fi


# SHORTENING OF URL 
if [ $SHORTEN -eq 1 ] && [ ${#link} -gt 36 ]; then
    loud "[info] Sending URL to shortener function"
    # this will overwrite the link
    yourls_shortener
fi
    
# Parsing enabled out systems. Find files in out_enabled, then import 
# functions from each and running them with variables already established.

posters=$(ls -A "$SCRIPT_DIR/out_enabled")

for p in $posters;do
    if [ "$p" != ".keep" ];then 
        loud "[info] Processing ${p%.*}..."
        send_funct=$(echo "${p%.*}_send")
        source "${SCRIPT_DIR}/out_enabled/${p}"
        loud "${SCRIPT_DIR}/out_enabled/${p}"
        eval ${send_funct}
        sleep 5
    fi
done
