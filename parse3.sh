#!/bin/bash

########################################################################
# Init
########################################################################

initialize () {
	COMPOSING=0
	SENSITIVE=0
	CONTENTWARNING=""
	
	if [ -f "$HOME/.config/rss_social.rc" ];then
		readarray -t line < "$HOME/.config/rss_social.rc"
		TOOTCLI=${line[0]}
		TWEETCLI=${line[1]}
        FBCLI=${line[2]}
        GPLUSCLI=${line[3]}
		RSSFEEDS=${line[4]}
		CACHEDIR=${line[5]}
		SENDNUM=${line[6]}        
        ENCODER=${line[7]}
	else
		echo "Configuration file not set up properly."
		exit
	fi

	if [ ! -d "$CACHEDIR" ];then 
		mkdir -p "$CACHEDIR"
        if [ ! -f "$CACHEFILE" ];then
            echo "" > "$CACHEFILE"
        fi
	fi

    CACHEFILE=$(echo "$CACHEDIR/urls")
    if [ ! -f "$CACHEFILE" ];then
        echo "" > "$CACHEFILE"
    fi

    TEMPDIR="$CACHEDIR/tempfiles"
    if [ ! -d "$TEMPDIR" ];then
        mkdir -p "$TEMPDIR"
    fi
    
	TEMPRSS=$(echo "$TEMPDIR/temprss.txt")
	echo "" > "$TEMPRSS"


}


########################################################################
# Expand all shortened urls
########################################################################
expand() {     
	resulturl=""
	resulturl=$(wget -O- --server-response $testurl 2>&1 | grep "^Location" | tail -1 | awk -F ' ' '{print $2}')
	if [ -z "$resulturl" ]; then
		resulturl=$(echo "$testurl")
	fi
	}

########################################################################
# Get the image from the RSS feed
########################################################################

getimg() {
    read
	wget -qO "$TEMPIMG" "$url"    
	if [ "$?" -gt 0 ];then
		#error getting image
		TEMPIMG=""
	fi
}

########################################################################
# Post each item to respective services
########################################################################
postit() {
	if grep -Fxq "$PERMLINK" "$CACHEFILE"
	then
		#echo "ERROR: $PERMLINK"
		echo "§ Already sent: $PERMLINK"
	else
        echo "§ Setting up posting for $PERMLINK"
        echo "$PERMLINK" >> "$CACHEFILE"
		# Remember sensitive and CW.  CW is a string

        #Caching the result and image
        uuid=$(uuidgen -r)
        bob=$(echo "$TDSTAMP-$uuid")
        ThisPostDir="$CACHEDIR/$bob"
        mkdir "$ThisPostDir"       
        ToEncodeString=$(echo "$ENCODER $PERMLINK")
        EncodedUrl=$($ENCODER "$PERMLINK")
 
		if [ -z "$TEMPIMG" ];then
			# post without image
			poststring=$(echo "$TITLE $PERMLINK")
			tweetstring=$(printf " --message \"%s  %s\"" "$TITLE" "$PERMLINK")
            if [ ! -z "$CONTENTWARNING" ];then
                tootstring=$(printf "post --spoiler-text \"%s\" \"%s  %s\"" "$CONTENTWARNING" "$TITLE" "$PERMLINK")
            else
                tootstring=$(printf "post \"%s  %s\"" "$TITLE" "$PERMLINK")
            fi
            #not sure if -remote will work with pexpect
            fbstring=$(printf " -c auto-submit -u https://www.facebook.com/sharer/sharer.php?u=%s" "$EncodedUrl")
            gplusstring=$(printf " -c auto-submit -u https://plus.google.com/share?url=%s" "$EncodedUrl")
		else
			# post with image
            imgname=$(basename "$TEMPIMG")
            cpstring="$TEMPIMG $ThisPostDir"
            out=$(eval cp "$cpstring")
            #rewriting the variable so I don't have to find it later.
            TEMPIMG2=$(echo "$ThisPostDir/$imgname")
            poststring=$(echo "$TITLE $PERMLINK $TEMPIMG")
			tweetstring=$(printf " --message \"%s  %s\" --file %s" "$TITLE" "$PERMLINK" "$TEMPIMG2")
            if [ ! -z "$CONTENTWARNING" ];then
                tootstring=$(printf "post --spoiler-text \"%s\" \"%s  %s\" --media %s" "$CONTENTWARNING" "$TITLE" "$PERMLINK" "$TEMPIMG2")
            else
                tootstring=$(printf "post \"%s  %s\" --media %s" "$TITLE" "$PERMLINK" "$TEMPIMG2")
            fi
            if [ "$SENSITIVE" == 1 ];then 
                tootstring=$(printf "%s --sensitive" "$tootstring")
            fi
            fbstring=$(printf " -auto-submit https://www.facebook.com/sharer/sharer.php?u=%s" "$EncodedUrl")
            gplusstring=$(printf " -auto-submit https://plus.google.com/share?url=%s" "$EncodedUrl")
		fi
#		echo "WOULD POST::"
#		echo "$tweetstring"
#		echo "$tootstring"
#		echo "$fbstring"
#       echo "$gplusstring"
        
        ThisPostText=$(echo "$ThisPostDir/posting.txt")
        touch "$ThisPostText"
        if [ "$TOOTCLI" != "FALSE" ];then  
            echo "$tootstring" >> "$ThisPostText"
        fi
        if [ "$TWEETCLI" != "FALSE" ];then  
            echo "$tweetstring" >> "$ThisPostText"
        fi
        if [ "$FBCLI" != "FALSE" ];then  
            echo "$fbstring" >> "$ThisPostText"
        fi
        if [ "$GPLUSCLI" != "FALSE" ];then  
            echo "$gplusstring" >> "$ThisPostText"
        fi        
		# Little bit of cleaning up here...
		if [ -f "$TEMPIMG" ];then
			rm "$TEMPIMG"
		fi
        sleep 2 #to make sure our dirnames are different
		read
	fi
}

########################################################################
# Parse feeds here
########################################################################
parse_feeds (){
	while read -r line; do
		case $line in 
			title* )     
				TITLE=$(echo "$line" | awk -F 'title=' '{print $2}' | awk -F 'http' '{print $1}')
				#strip url off title if it is there 
				COMPOSING=1
			;;
            updated* )
                DateSTAMP=$(echo "$line" | awk -F 'updated=' '{print $2}' | awk -F 'T' '{print $1}')
                TimeSTAMP=$(echo "$line" | awk -F 'updated=' '{print $2}' | awk -F 'T' '{print $2}' | awk -F '-' '{print $1}')
                TDSTAMP=$(date --date="$DateSTAMP $TimeSTAMP" +"%Y%m%d%H%M%s")
            ;;
			link/@href* ) 
				testurl=$(echo "$line" | awk -F 'link/@href=' '{print $2}')
				expand
				#strip off any _utm things and/or stupid :large things on the end
				url=$(echo "$resulturl" | awk -F '?utm_' '{print $1}' | awk -F ':' '{print $1":"$2 }')
				case $url in
					*jpg*)
						TEMPIMG="$TEMPDIR/temp.jpg"
						getimg
					;;
					*png*)
						TEMPIMG="$TEMPDIR/temp.png"
						getimg
					;;
					*gif*)
						TEMPIMG="$TEMPDIR/temp.gif"
						getimg
					;;
					*twitter*)
						echo "store, maybe useful?"
					;;
					*)
						PERMLINK="$url"
					;;
				esac
			;;
			source/link/@href*) 
				testurl=$(echo "$line" | awk -F 'link/@href=' '{print $2}')
				expand
				#strip off any _utm things and/or stupid :large things on the end
				sourceurl=$(echo "$resulturl" | awk -F '?utm_' '{print $1}' | awk -F ':' '{print $1":"$2 }' | grep -v -e "atom" -e "rss" -e "xml")
				#If there's something here and not the permalink (like if it's to a tweet?)...
				if [ -z "$PERMLINK" ];then
					PERMLINK="$sourceurl"
				fi            
			;;
			# content is not parsed for here because it's usually html and way too long
			# I can release something later for that, I guess.
			/feed/entry* )
				# If you're currently putting together something, you've hit the next entry
				if [ $COMPOSING == 1 ];then
					postit
					COMPOSING=0
				fi
			;;
			link/@rel=enclosure*)  
				# This is probably the end of one.... (also triggers on the last entry)
				if [ $COMPOSING == 1 ];then
					postit
					COMPOSING=0
				fi
				;;
			esac
            					
	done < "$TEMPRSS"
    postit
					COMPOSING=0
}

########################################################################
# Pull in feeds here
########################################################################
pull_feeds () {
	SENSITIVE=0
	CONTENTWARNING=""

	while read -r line; do
        case $line in 
		@SEN*) SENSITIVE=1
        ;;
		# NEED TO CHECK HERE SO THAT IF SOMEONE LEAVES IT OFF...
		@CON*)     
            CONTENTWARNING=$(echo "$line" | awk -F '@CON=' '{print $2}')
        ;;
		@FEED*)
            FEED=$(echo "$line" | awk -F '@FEED=' '{print $2}')
            curl -s --max-time 10 "$FEED" | xml2 | sed 's|/feed/entry/||' > "$TEMPRSS"
            #cat "$TEMPRSS"
            #echo "$FEED"
            #sleep 10
			parse_feeds
			rm "$TEMPRSS"
            SENSITIVE=0
            CONTENTWARNING=""
            ;;
		*) echo "ignoring commented line" ;;
        esac
	done < "$RSSFEEDS"

}

########################################################################
# Main
########################################################################
initialize
pull_feeds

#Clean
