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

##############################################################################
# Show the Help
##############################################################################
display_help(){
    echo "###################################################################"
    echo "# flatpak run com.stevesaus.agaetr [options] "
    echo "# Info ############################################################"
    echo "# --help:  show help "
    # --locations: print config and data locations
    # --readme: display the README on the console
    # --config-toot  toot login_cli
    # --config-shaarli [shaarli]
#url = https://shaarli.stevesaus.me/
#secret = totallyfakesecret
# shaarli must be run with --config CONFIG
# --config-wallabag wallabag config
   # bash /home/steven/.var/app/org.flatpak.agaetr/config/toot/config.json

    echo "# --readme: show README.md"
    echo "create shaarli config create toot config create wallabag config create email send config create savelocation create rssout location"
    echo "# Setup ###########################################################"
    echo "# Setup"
    echo "# --pico:  Produce pico templates with example htpasswd"
    echo "# --example: Produce $HOME/.config/orindi/orindi.ini.template"
    echo "# Usage ###########################################################"    
    echo "# Running it"
    echo "# --muna [URL]: unredirect a URL "
    echo "# --keyword: Keyword that applies to all input that follows"
    echo "# --version: report version  "
    echo "# Input Source ####################################################"
    echo "# --stdin: Input is coming from stdin, not a file"
    echo "# --file [FILENAME]: path to file. Needs to be in user's $HOME"
    echo "# --dir [DIRECTORY]: A maildir to process, requires [KEYWORD]"
    echo "  "
    echo "# stdin file and dir MUST BE THE LAST AND ARE EXCLUSIVE "
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
        cp /cfg/feeds.ini "${XDG_CONFIG_HOME}/agaetr/feeds.ini"
    fi
    if [ ! -f "${XDG_CONFIG_HOME}/agaetr/cw.ini" ];then
        cp /cfg/cw.ini "${XDG_CONFIG_HOME}/agaetr/cw.ini"
    fi        
}


configurators(){
    echo "Which would you care to configure?"
    select module in shaarli wallabag mastodon email twitter save quit
    do

    case ${module} in
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
        "twitter");;
        
        `APP_KEY = ""`  
`APP_SECRET = ""`  
`OAUTH_TOKEN = ""`  
`OAUTH_TOKEN_SECRET = ""`  
these go into tweet.py
        
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
                    check_for_flatpak_config
                    # This *should* work:
                    # https://unix.stackexchange.com/questions/540094/i-want-to-pass-stdin-to-a-bash-script-to-an-python-script-called-in-that-bash-sc
                    /app/bin/python3 /app/bin/orindi_parse.py
                    clean_temp_keyword
                    exit
                    ;;
        --file)     shift
                    if [ -f "${1}" ];then
                        check_for_flatpak_config
                        FILENAME="${1}"
                        /app/bin/python3 /app/bin/orindi_parse.py "${FILENAME}"
                        clean_temp_keyword
                        exit
                    else
                        echo "Not a filename!"
                        exit 
                    fi
                    ;; 
        *)          shift;;
    esac
done   

clean_temp_keyword
