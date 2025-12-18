#!/usr/bin/bash

##############################################################################
#
#  Sending helper script for agaetr
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################


function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
	fi
}



function bluesky_send {

    tempfile=$(mktemp)

    if [ "$title" == "$link" ];then
        title=""
    fi

    binary=$(grep 'bluesky =' "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" | sed 's/ //g' | awk -F '=' '{print $2}')

    if [ "$description2" != "" ];then
        description2="Archive: ${description2}"
    fi

    # because bsky has a 300 character limit
    if [ "${shortlink}" = "" ];then
        shortlink="${link}"  #in case it's not set
    fi

    outstring=$(printf "%s\n\n%s\n\n%s\n\n%s\n\n%s" "${title}" "${description}" "${description2}" "${shortlink}" "${hashtags}")
	if [ ${#outstring} -gt 290 ];then
        # testing length description, which is either from the feed, null (default newsboat/mutt), or *user set* from newsboat/mutt.
        tlen=$(( ${#title} + 3 )) # accounting for newlines
        d1len=$(( ${#description} + 3 ))
        d2len=$(( ${#description2} + 3 ))
        hashlen=$(( ${#hashtags} + 3 ))
        urlen=$(( ${#shortlink} + 3 ))
        total_length=$(( tlen + d1len + d2len + hashlen + urlen ))
		echo "${total_length}" >> /home/steven/tmp/bslushit.txt
		diff_len=$(( 290 - total_length ))
		if [ "$diff_len" -gt 0 ]; then
			printf "%s  \n\n%s  \n\n%s  \n\n%s  \n\n%s" "${title}" "${description}" "${description2}" "${shortlink}" "${hashtags}" > "${tempfile}"
        else
			# converting diff_len into abs sorta
			diff_len=${diff_len#-}
			if [[ "$hashlen" -gt "$diff_len" ]];then
                printf "%s  \n\n%s  \n\n%s  \n\n%s" "${title}" "${description}" "${description2}" "${shortlink}" > "${tempfile}"
            else
                diff_len=$(( diff_len - hashlen ))
				if [[ "$d2len" -gt "$diff_len" ]];then
                    trimto=$(( d2len - diff_len - 4 ))
                    description2="${description2:0:trimto}... "
                    printf "%s  \n\n%s  \n\n%s  \n\n%s" "${title}" "${description}" "${description2}" "${shortlink}" > "${tempfile}"
                else
                    diff_len=$(( diff_len - d2len ))
                    # the difference was more than we could cut out of d2len
					if [[ "$d1len" -gt "$diff_len" ]];then
                        # use d1len and diff_len to figure out how much to trim off d1len, post.
                        trimto=$(( d1len - diff_len - 4 ))
                        description="${description:0:trimto}... "
                        printf "%s  \n\n%s  \n\n%s" "${title}" "${description}" "${shortlink}" > "${tempfile}"
                    else
                        diff_len=$(( diff_len - d1len ))
                        # the difference was more than we could cut out of d1len
                        trimto=$(( tlen - diff_len - 4 ))
                        title="${title:0:trimto}... "
                        printf "%s  \n\n%s" "${title}" "${shortlink}" > "${tempfile}"
                        # use tlen and diff_len to figure out how much to trim off title, post.
                        # this test HAS to pass,
                    fi
                fi
            fi
        fi
    else
        # I realize this is a double test.
        printf "%s \n\n%s \n\n%s \n%s" "${title}" "${description}" "${description2}" "${shortlink}" "${hashtags}" > "${tempfile}"
    fi


    # Get the image, if exists, then send the post
    if [ ! -z "${imgurl}" ];then
        if [ -f "${imgurl}" ];then
            filename=$(basename -- "${imgurl}")
            extension="${filename##*.}"
            Outfile=$(mktemp --suffix=.${extension})
            cp "${imgurl}" "${Outfile}"
        else
            Outfile=$(mktemp)
            curl "${imgurl}" -o "${Outfile}" --max-time 60 --create-dirs -s
        fi
        if [ -f "${Outfile}" ];then
            loud "[info] Image obtained, resizing."
            if [ -f /usr/bin/convert ];then
                /usr/bin/convert -resize 800x512\! "${Outfile}" "${Outfile}"
            fi
            if [ ! -z "${ALT_TEXT}" ];then
                Limgurl=$(printf " --image %s --image-alt \"%s\"" "${Outfile}" "${ALT_TEXT}")
            else
                # I suppose there could be another call to ai_gen_alt_text here
                Limgurl=$(printf " --image %s --image-alt \"An image pulled automatically from the post for decorative purposes only.\"" "${Outfile}")
            fi
        else
            Limgurl=""
        fi
    else
        Limgurl=""
    fi

    postme=$(printf "cat %s | %s post --stdin %s" "${tempfile}" "${binary}"  "${Limgurl}")
    loud "${postme}"
    eval "${postme}";poster_result_code=$?     # returns 0|1


    if [ -f "${Outfile}" ];then
        rm "${Outfile}"
    fi
    if [ -f "${tempfile}" ];then
        rm "${tempfile}"
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
    echo "[info] Function bluesky ready to go."
else
    if [ "$#" = 0 ];then
        echo -e "Please call this as a function or with \nthe url as the first argument and optional \ndescription as the second."
    else
        if [ "${1}" == "--loud" ];then
            LOUD=1
            shift
        else
            LOUD=0
        fi
        link="${1}"
        if [ ! -z "$2" ];then
            title="$2"
        fi
        bluesky_send
    fi
fi
