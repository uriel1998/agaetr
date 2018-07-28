#!/bin/bash

########################################################################
# Init
########################################################################

initialize () {
	TEMPFILE=$(mktemp)
    TEMPDIR=$(mktemp -d)
	
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

    CACHEFILE=$(echo "$CACHEDIR/urls")

}

# for directories in cachedir
# get the posting.txt file (tempimg, if it exists, will be encoded)
# read the posting.txt file - first line is tweet second tood
# maybe use an array there?
# execute the programs

NUMSENT=0

# Might have an option for sorted or random later, but for right now...
# Getting the cache dirs in numerical order (e.g. first in first out)
# The first line will actually be the base dir but won't have the 
# appropriate file, so it'll skip
find "$CACHEDIR" -maxdepth 1 -type d -exec echo {} \; | sort > "$TEMPFILE"

while read -r d; do
    if [ -d "$d" ]; then
        if [ -f "$d/posting.txt" ];then
            readarray -t line < "$d/posting.txt"
            ToToot=${line[0]}
            ToTweet=${line[1]}
            ToFB=${line[2]}
            ToGPlus=${line[3]}
        
            if [ -z "$ToToot" ];then
                SocialString=$(echo "$TOOTCLI $ToToot")
                output=$(eval "$SocialString")
                echo "$output"
            fi
            if [ -z "$ToTweet" ];then
                SocialString=$(echo "$TWEETTCLI $ToTweet")
                output=$(eval "$SocialString")
                echo "$output"
            fi
            if [ -z "$ToFB" ];then
                SocialString=$(echo "$FBCLI $ToFB")
                output=$(eval "$SocialString")
                echo "$output"
            fi
            ((NUMSENT++))
            rm -rf "$d"
        else
            echo "Not a post file"
        fi   

        
        if [ "$NUMSENT" -ge "$SENDNUM" ];then
            exit
        fi
    fi
	done < "$TEMPFILE"
}

#Clean

rm -rf "$TEMPDIR"
rm "$TEMPFILE"
