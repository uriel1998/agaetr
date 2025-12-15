#!/bin/bash

##############################################################################
#
#  sending script
#  (c) Steven Saus 2024
#  Licensed under the MIT license
#
##############################################################################

function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
			echo "$@" 1>&2
}

function png_capture_send {

    ConfigFile="${XDG_CONFIG_HOME:-$HOME/.config}/agaetr/agaetr.ini"
    if [ ! -f "${ConfigFile}" ];then
        loud "[ERROR] Configuration not found"
        exit 97
    fi


    # environment
    if [ "${save_directory}" != "" ] && [ -d "${save_directory}" ];then
        SAVEDIR="${save_directory}"
    else
        #ini
        save_directory=$(grep 'save_directory' "${ConfigFile}" | sed 's/ //g' | awk -F '=' '{print $2}')
        if [ "${save_directory}" != "" ] && [ -d "${save_directory}" ];then
            SAVEDIR="${save_directory}"
        else
            SAVEDIR=$(xdg-user-dir DOWNLOAD)
            if [ ! -d "${SAVEDIR}" ];then
                SAVEDIR="${HOME}"
            fi
        fi
    fi
    if [ -f $(which detox) ];then
        dttitle=$(echo "${title}" | detox --inline)
        outpath="${SAVEDIR}/${dttitle}.png"
    else
        outpath="${SAVEDIR}/${title}.png"
    fi
    binary=$(which cutycapt)
    if [ ! -f "$binary" ];then
        binary=$(grep 'cutycapt =' "${ConfigFile}" | sed 's/ //g' | awk -F '=' '{print $2}')
    fi
    if [ -f "$binary" ];then
        loud "[info] Writing to ${outpath}"
        outstring=$(printf "%s" "$link" )
        outstring=$(echo "$binary --smooth --insecure --url=\"$outstring\" --out=\"${outpath}\"")
        eval ${outstring}
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
    echo "[info] Function ready to go."
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
            title="$2" # These should already be cleaned.
        fi
        png_capture_send
    fi
fi
