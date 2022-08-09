#   !/bin/bash

##############################################################################
#
#  Flatpak / other control file for agaetr
#  (c) Steven Saus 2022
#  Licensed under the MIT license
#
##############################################################################

VERSION="0.1.0"

# I want to check if it's using the $HOME or flatpak ones here,
echo "$XDG_CONFIG_HOME"
echo "$XDG_DATA_HOME"
echo "$XDG_CACHE_HOME"
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

##############################################################################
# Show the Help
##############################################################################
display_help(){
    echo "###################################################################"
    echo "# flatpak run com.stevesaus.agaetr [options] "
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

display_readme(){
    ${PAGER:-more} < /app/bin/cfg/README.md
}


check_for_config(){
    if [ ! -d "${XDG_CONFIG_HOME}/agaetr" ];then
        mkdir -p "${XDG_CONFIG_HOME}/agaetr"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/agaetr.ini" ];then
        cp /cfg/agaetr.ini "${XDG_CONFIG_HOME}/agaetr/agaetr.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/feeds.ini" ];then
        cp /cfg/empty_feeds.ini "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/cw.ini" ];then
        cp /cfg/cw.ini "${XDG_CONFIG_HOME}/agaetr/cw.ini"
    fi        
}


configurators(){
    echo "Which would you care to configure?"
    select module in cookies shaarli wallabag mastodon email twitter wayback save feeds ini quit
    do

    case ${module} in
        "feeds") 
            feednum=$(date +%Y%m%d%H%m%S)
            echo "Does this feed require preprocessing [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                echo "Please enter the original source of the feed with leading https://."
                read src
                echo "Please enter the command to use for preprocessing."
                # IFS change so we can get quotes, I hope
                OIFS=$IFS
                IFS=$'\n'
                read cmd
                IFS=$OIFS
                echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                read url
            else
                echo "Is this feed from a file? [y/N]?"
                read ans
                if [ "$ans" == "y" ];then
                    echo "Please enter the *relative* filepath to save the feed at, with leading slash."
                    read url
                    # mkdir -p for the filepath and touch the file here
                else
                    echo "Please enter the source of the feed, with leading https://"
                    read url
                    # check for starting with http? 
                fi
            fi
            echo "Should the feed images be marked sensitive by default? [y/N]?"
            read ans
            if [ "$ans" == "y" ];then
                sensitive = yes
            else
                sensitive = no

            echo "What should the content warning on every post from this feed be?"
            echo "Leave blank for no automatic warning on EVERY post from this feed."
            read ans
            if [ "$ans" != "" ];then
                ContentWarning = yes
                GlobalCW = "${ans}"
            else
                #if empty
                ContentWarning = no
                    
            fi
            
            "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
            ;;
        "wayback") 
            echo "You must register for an API key at https://archive.org/account/s3.php"
            echo "Please input the access key"
            read accesskey
            echo "Please input the secret key"
            read accesssecret
            inifile="${XDG_CONFIG_HOME}/agaetr/agaetr.ini"            
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
        "wallabag") /app/wallabag config;;
        "mastodon") /app/toot login_cli;;
        "shaarli") 
            echo "Please put the URL of your shaarli instance"
            read shaarli_url
            echo "Please input the API secret (under Tools, Configure)"
            read shaarli_secret
            shaarli_config="${XDG_CONFIG_HOME}/shaarli.cfg"
            echo "[shaarli]" > "${shaarli_config}"
            echo "${shaarli_url}" >> "${shaarli_config}"
            echo "${shaarli_secret}" >> "${shaarli_config}"
            ;;
        "email");;
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
            eval $(printf "sed -i \'/^APP_KEY =.*/s/.*/APP_KEY = \"${appkey}\"/' /app/tweet.py")
            eval $(printf "sed -i \'/^APP_SECRET =.*/s/.*/APP_SECRET = \"${appsecret}\"/' /app/tweet.py")
            eval $(printf "sed -i \'/^OAUTH_TOKEN =.*/s/.*/OAUTH_TOKEN = \"${oauthtoken}\"/' /app/tweet.py")
            eval $(printf "sed -i \'/^OAUTH_TOKEN_SECRET =.*/s/.*/OAUTH_TOKEN_SECRET = \"${oauthtokensecret}\"/' /app/tweet.py")
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
        --init)     display_help
                    echo "W@OO"
                    check_for_config
                    exit
        --help)     display_help
                    exit
                    ;;
        --readme)   display_readme
                    exit
                    ;;                    
        *muna)     # Just running muna, nothing to see here.
                    shift
                    URL="${1}"
                    /app/bin/muna.sh "${URL}"
                    exit    
                    ;;
        --version)  echo "${VERSION}"; check_for_flatpak_config; exit ;;
        --stdin)    # I'm not sure how to ensure this passes the stdin stream?
                    # this would be like for sending a single url 
                    check_for_flatpak_config
                    # This *should* work:
                    # https://unix.stackexchange.com/questions/540094/i-want-to-pass-stdin-to-a-bash-script-to-an-python-script-called-in-that-bash-sc
                    /app/bin/python3 /app/bin/orindi_parse.py
                    clean_temp_keyword
                    exit
                    ;;
                    
        --pull)     # run rss_preprocessor
                    # run agaetr_parse.py
                    ;;
        --push)     # no special things, just run the program with sane defaults of 
                    # pushing from all queues to all configured outsources
                    ;;
        --file)     # to pull in a specific xml file (from outside flatpak??)
                    ;; 
        *)          shift;;
    esac
done   

clean_temp_keyword
