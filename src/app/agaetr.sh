#!/bin/bash

##############################################################################
#
#  Control file for agaetr
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
##############################################################################


###############################################################################
# Establishing XDG directories, or creating them if needed.
#
# Likewise with initial INI files
###############################################################################
VERSION="0.1.0"
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOUD=0

function loud() {
    if [ $LOUD -eq 1 ];then
        echo "$@"
    fi
}


if [ -z "${XDG_DATA_HOME}" ];then
    export XDG_DATA_HOME="${HOME}/.local/share"
    export XDG_CONFIG_HOME="${HOME}/.config"
    export XDG_CACHE_HOME="${HOME}/.cache"
fi

if [ ! -d "${XDG_CONFIG_HOME}" ];then
    echo "Your XDG_CONFIG_HOME variable is not properly set and does not exist."
    exit 99
fi

check_for_config(){
    if [ ! -d "${XDG_CONFIG_HOME}/agaetr" ];then
        mkdir -p "${XDG_CONFIG_HOME}/agaetr"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
        cp /app/etc/agaetr.ini "${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
        cp /app/etc/empty_feeds.ini "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/cw.ini" ];then
        cp /app/etc/cw.ini "${XDG_CONFIG_HOME}/agaetr/cw.ini"
    fi        
    if [ ! -d "${XDG_DATA_HOME}/agaetr" ];then
        mkdir -p "${XDG_DATA_HOME}/agaetr"
    fi
    if [ ! -f "${XDG_DATA_HOME}/agaetr/README.md" ];then
        cp /app/share/agaetr/README.md "${XDG_DATA_HOME}/agaetr/README.md"
    fi        
    if [ ! -f "${XDG_DATA_HOME}/agaetr/LICENSE.md" ];then
        cp /app/share/agaetr/LICENSE.md "${XDG_DATA_HOME}/agaetr/LICENSE.md"
    fi        




}

##############################################################################
# Show the Help
##############################################################################
display_help(){
    echo "###################################################################"
    echo "# Standalone: /path/to/agaetr.sh [options]"
    echo "# Flatpak: flatpak run com.stevesaus.agaetr [options] "
    echo "# Info ############################################################"
    echo "# --help:  show help "
    echo "# --configure: enter configurator"
    echo "# --locations: print config and data locations"
    echo "# --readme: display the README on the console"
    echo "# Usage ###########################################################"    
    echo "# Running it"
    # pull
    # push
    echo "# --muna [URL]: unredirect a URL "
    echo "# --keyword: Keyword that applies to all input that follows"
    echo "# --version: report version  "
    echo "# Input Source ####################################################"
    echo "# --stdin: Input is coming from stdin, not a file"
    echo "# --file [FILENAME]: path to file. Needs to be in user's $HOME"
    echo "###################################################################"
}

##############################################################################
# Show the README
##############################################################################

display_readme(){
    if [ -f "${XDG_DATA_HOME}"/agaetr/README.md ];then
        ${PAGER:-more} < "${XDG_DATA_HOME}"/agaetr/README.md
        ${PAGER:-more} < "${XDG_DATA_HOME}"/agaetr/LICENSE.md
    else
        if [ -f "${SCRIPT_DIR}/README.md" ];then
            ${PAGER:-more} < ${SCRIPT_DIR}/README.md
            ${PAGER:-more} < ${SCRIPT_DIR}/LICENSE.md
        else
            echo "README.md not found!"
            exit 99
        fi
    fi
    exit
}


##############################################################################
# Invoke the configurators
##############################################################################

configurators(){
    echo "Which would you care to configure?"
    select module in cookies shaarli wallabag mastodon email twitter wayback save feeds quit
    do
    
    inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"  
    case ${module} in
        "feeds") 
            writefeed=""
            feednum=$(date +%Y%m%d%H%m%S)
            writefeed=$(printf "%s\n[Feed%s]" "${writefeed}" "${feednum}")
            echo "Does this feed require preprocessing [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                echo "Please enter the original source of the feed with leading https://."
                read src
                writefeed=$(printf "%s\nsrc = %s" "${writefeed}" "${src}")
                echo "Please enter the command to use for preprocessing."
                # IFS change so we can get quotes, I hope
                OIFS=$IFS
                IFS=$'\n'
                read cmd
                writefeed=$(printf "%s\ncmd = %s" "${writefeed}" "${cmd}")
                IFS=$OIFS
                echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                read url
                writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
            else
                echo "Is this feed from a file? [y/N]?"
                read ans
                if [ "$ans" == "y" ];then
                    echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                    read url
                    writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
                else
                    echo "Please enter the source of the feed, with leading https://"
                    read url
                    # check for starting with http? 
                    writefeed=$(printf "%s\nurl = %s" "${writefeed}" "${url}")
                fi
            fi
            echo "Should the feed images be marked sensitive by default? [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                writefeed=$(printf "%s\nsensitive = yes" "${writefeed}")
            else
                writefeed=$(printf "%s\nsensitive = no" "${writefeed}")
            fi
            echo "What should the content warning on every post from this feed be?"
            echo "Leave blank for no automatic warning on EVERY post from this feed."
            read ans
            if [ "$ans" != "" ];then
                writefeed=$(printf "%s\nContentWarning = yes" "${writefeed}")
                writefeed=$(printf "%s\nGlobalCW = %s" "${writefeed}" "${ans}")
            else
                writefeed=$(printf "%s\nContentWarning = no" "${writefeed}")
                writefeed=$(printf "%s\nGlobalCW = " "${writefeed}")
            fi
            echo "This is the proposed configuration:"
            echo -e "${writefeed}"
            echo "Is this acceptable? [y/N]"
            read ans
            if [ "${ans}" == "y" ];then
                # write it all to the feed ini file
                printf "%s\n" >> "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
            else
                echo "Aborting."
            fi
            ;;
        "wayback") 
            echo "You must register for an API key at https://archive.org/account/s3.php"
            echo "Please input the access key"
            read accesskey
            echo "Please input the secret key"
            read accesssecret
          
            eval $(printf "sed -i \'/^wayback_access =.*/s/.*/wayback_access = \"${accesskey}\"/' ${inifile}")
            eval $(printf "sed -i \'/^wayback_secret =.*/s/.*/wayback_secret = \"${accesssecret}\"/' ${inifile}")
            ;;
        "cookies") 
            if [ ! -f "${XDG_CONFIG_HOME}/cookies.txt" ];then
                echo "Please copy your cookie file to ${XDG_CONFIG_HOME}/cookies.txt"
            else
                echo "Cookie file already exists at ${XDG_CONFIG_HOME}/cookies.txt"
            fi
            ;;
        "wallabag") 
            binary=$(grep 'wallabag =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default wallabag binary with ${binary} found on $PATH"
                    eval $(printf "sed -i \'/^wallabag =.*/s/.*/wallabag = \"${binary}\"/' ${inifile}")
                else
                    echo "No wallabag binary found!"
                    exit 99
                fi
            fi
            eval $("${binary}" config)
            ;;

        "mastodon") 
            binary=$(grep 'toot =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default toot binary with ${binary} found on $PATH"
                    eval $(printf "sed -i \'/^toot =.*/s/.*/toot = \"${binary}\"/' ${inifile}")
                else
                    echo "No toot binary found!"
                    exit 99
                fi
            fi
            eval $("${binary}" login_cli)
            ;;
        "shaarli") 
            binary=$(grep 'shaarli =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which shaarli)
                if [ -f "${binary}" ];then
                    echo "Replacing default shaarli binary with ${binary}"
                    eval $(printf "sed -i \'/^shaarli =.*/s/.*/shaarli = \"${binary}\"/' ${inifile}")
                else
                    echo "No shaarli binary found!"
                    exit 99
                fi
            fi
            config_number=$(grep -c 'shaarli_config' "${inifile}")
            echo "Please give this configuration a name."
            read shaarli_name
            echo "Please put the URL of your shaarli instance with leading https://"
            read shaarli_url
            echo "Please input the API secret (under Tools, Configure)"
            read shaarli_secret
            shaarli_config="${XDG_CONFIG_HOME}/shaarli/agaetr_shaarli${config_number}.cfg"
            echo "[shaarli]" > "${shaarli_config}"
            echo "${shaarli_url}" >> "${shaarli_config}"
            echo "${shaarli_secret}" >> "${shaarli_config}"
            echo " " >> "${inifile}"
            echo "[shaarli_config ${shaarli_name}]" >> "${inifile}"
            echo "shaarli_config = ${shaarli_config}" >> "${inifile}"
            ;;
        "email")
            echo "Please put the name or address of your SMTP server (NOT port)"
            read smtp_server
            echo "Please input the port of your SMTP server"
            read smtp_port
            echo "Please input the SMTP username"
            read smtp_username
            echo "Please input the SMTP user password"
            read smtp_password       
            inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
            TempVar=$(cat "${inifile}" | grep -v smtp_)
            echo "${TempVar}" > "${inifile}"
            echo "smtp_server = ${smtp_server}" >> "${inifile}"
            echo "smtp_port = ${smtp_port}" >> "${inifile}"
            echo "smtp_username = ${smtp_username}" >> "${inifile}"
            echo "smtp_password = ${smtp_password}" >> "${inifile}"
            ;;
        "twitter")
            binary=$(grep 'twython =' "${inifile}" | sed 's/ //g' | awk -F '=' '{print $2}')
            if [ ! -f "${binary}" ];then
                binary=$(which tweet)
                if [ -f "${binary}" ];then
                    echo "Replacing default tweet binary with ${binary} found on $PATH"
                    eval $(printf "sed -i \'/^twython =.*/s/.*/twython = \"${binary}\"/' ${inifile}")
                else
                    echo "No twython binary found!"
                    exit 99
                fi
            fi
            echo "You must register a **USER** app at https://apps.twitter.com"
            echo "and get the **user** API codes for these next prompts."
            echo "Please input the APP KEY"
            read appkey
            echo "Please input the APP SECRET"
            read appsecret
            echo "Please input the OAUTH TOKEN"
            read oauthtoken
            echo "Please input the OAUTH TOKEN SECRET"
            read oauthtokensecret
            eval $(printf "sed -i \'/^APP_KEY =.*/s/.*/APP_KEY = \"${appkey}\"/' ${binary}")
            eval $(printf "sed -i \'/^APP_SECRET =.*/s/.*/APP_SECRET = \"${appsecret}\"/' ${binary}")
            eval $(printf "sed -i \'/^OAUTH_TOKEN =.*/s/.*/OAUTH_TOKEN = \"${oauthtoken}\"/' ${binary}")
            eval $(printf "sed -i \'/^OAUTH_TOKEN_SECRET =.*/s/.*/OAUTH_TOKEN_SECRET = \"${oauthtokensecret}\"/' ${binary}")
            ;;
        "save")
            echo "All saved files  stored under ${XDG_DATA_HOME}/agaetr"
            echo "If you would like to have a symlink, type"
            echo "ln -s ${XDG_DATA_HOME}/agaetr /desired/path"
            ;;
        *) echo "Exiting configuration." break ;;
    esac
    done
}



##############################################################################
# Get command-line parameters
##############################################################################

while [ $# -gt 0 ]; do
    option="$1"
    case $option in
        --loud)     export LOUD=1
                    shift
                    ;;
        --init)     display_help
                    check_for_config
                    exit
                    ;;
        --help)     display_help
                    exit
                    ;;
        --readme)   check_for_config #includes moving README!
                    display_readme
                    exit
                    ;;                    
        *muna)     # Just running muna, nothing to see here.
                    shift
                    URL="${1}"
                    "${SCRIPT_DIR}"/muna.sh "${URL}"
                    exit    
                    ;;
        --version)  echo "${VERSION}"; check_for_config; exit ;;
        --stdin)    # TODO
                    # I'm not sure how to ensure this passes the stdin stream?
                    # this would be like for sending a single url 
                    check_for_config
                    # This *should* work:
                    # https://unix.stackexchange.com/questions/540094/i-want-to-pass-stdin-to-a-bash-script-to-an-python-script-called-in-that-bash-sc
                    python_bin=$(which python3)
                    "${python_bin}" "${SCRIPT_DIR}"/agaetr_parse.py
                    clean_temp_keyword
                    exit
                    ;;
        --pull)     # perform a pull run. can be combined with other inputs
                    "${SCRIPT_DIR}"/rss_preprocessor.sh
                    python_bin=$(which python3)
                    "${python_bin}" "${SCRIPT_DIR}"/agaetr_parse.py                    
                    ;;
        --push)     # no special things, just run the program with sane defaults of 
                    # pushing from all queues to all configured outsources
                    "${SCRIPT_DIR}"/agaetr_send.sh
                    ;;
        --url)      # running a single url. Positional arguments
                    # --url [--queue] URL
                    shift
                    queue=0
                    if [ "${1}" == "--queue" ];then
                        shift
                        URL="${1}"
                        "${SCRIPT_DIR}"/singleurl_preprocessor.sh --queue --url "${URL}"
                    else
                        URL="${1}"
                        "${SCRIPT_DIR}"/singleurl_preprocessor.sh --queue --url "${URL}"
                    fi
                    exit
                    ;;
        --locations) 
                    # I want to check if it's using the $HOME or flatpak ones here,
                    #check_for_config
                    echo "$XDG_CONFIG_HOME"
                    echo "$XDG_DATA_HOME"
                    echo "$XDG_CACHE_HOME"
                    exit
                    ;;
        --file)     # to pull in a specific xml file (from outside flatpak??) it 
                    # would have to be via stdin then, right?
                    ;; 
        *)          shift;;
    esac
done   

# clean_temp_keyword
