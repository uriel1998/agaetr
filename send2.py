#!/usr/bin/python3

import feedparser
import time
from subprocess import check_output
import sys
import json
import wget
from bs4 import BeautifulSoup
from pprint import pprint
import configparser
import os
from os.path import expanduser
from appdirs import *
from pathlib import Path
import shutil
from urllib.parse import urlparse

########################################################################
# Init
########################################################################

appname = "rss_social"
appauthor = "Steven Saus"
#Where to store data, duh
datadir = user_data_dir(appname)
cachedir = user_cache_dir(appname)
configdir = user_config_dir(appname)
if not os.path.isdir(datadir):
    os.makedirs(user_data_dir(appname))
#local cache
if not os.path.isdir(cachedir):
    os.makedirs(user_cache_dir(appname))
#YUP
if not os.path.isdir(configdir):
    os.makedirs(user_config_dir(appname))

ini = os.path.join(configdir,'rss_social.ini')
db = os.path.join(datadir,'posts.db')
tmp = os.path.join(cachedir,'posts.db')

#read from INI how many posts to make
#read from INI what tools to use
#read from db file post # of lines
#parse line
#download img (!)
#ensure image still exists!
#post line to each service
#when done, trim post # of lines from db file

########################################################################
# Read ini section
########################################################################

config = configparser.ConfigParser()
config.read(ini)
sections=config.sections()

mastoposter = config['DEFAULT']['mastoposter']
birdposter = config['DEFAULT']['birdposter']


########################################################################
# Parse the db posting line
########################################################################
def parse_that_line(dataline):
    
    linetime,linetitle,linelink,linecw,lineimgalt,lineimgurl,linehashtags = dataline.split("|")

    #getting image
    a = urlparse.urlparse(lineimgurl)
    imgfilename = os.path.basename(a.path)
    lineimgloc = os.path.join(cachedir,imgfilename)
    print('Beginning file download with wget module')
    wget.download(lineimgurl, lineimgloc) 
    if not os.path.isfile(lineimgloc):
        # post without image
        
        ###THIS IS FROM THE BASH VERSION I NEED TO CHANGE IT
        tweetstring=$(printf " --message \"%s  %s\"" "$TITLE" "$PERMLINK" "$HASHTAGS")
        if linecw is None:
            tootstring=$(printf "post \"%s  %s\"" "$TITLE" "$PERMLINK" "$HASHTAGS")
        else:
            tootstring=$(printf "post --spoiler-text \"%s\" \"%s  %s\"" "$CONTENTWARNING" "$TITLE" "$PERMLINK" "$HASHTAGS")
    else:
		tweetstring=$(printf " --message \"%s  %s\" --file %s" "$TITLE" "$PERMLINK" "$HASHTAGS" "$TEMPIMG2")
           if [ ! -z "$CONTENTWARNING" ];then
                tootstring=$(printf "post --spoiler-text \"%s\" \"%s  %s\" --media %s" "$CONTENTWARNING" "$TITLE" "$PERMLINK" "$TEMPIMG2")
            else
                tootstring=$(printf "post \"%s  %s\" --media %s" "$TITLE" "$PERMLINK" "$TEMPIMG2")
            fi
            if [ "$SENSITIVE" == 1 ];then 
                tootstring=$(printf "%s --sensitive" "$tootstring")
            fi
     
    
    
    #if CW == "no":
    
    
    
    
    #what posting services are configured?
    #run posting services

########################################################################
# Begin loop over feedlist
########################################################################

Loops = config['DEFAULT']['ArticlesPerRun']
LoopsPerformed = 0

# Open the file with read only permit
f = open(db)
while LoopsPerformed < Loops:
    line = f.readline()
    LoopsPerformed += 1
    #this goes to the posting bit
    parse_that_line(line)

#finished posting

#print the rest to the tempfile
out = open(tmp, 'w')
while line:
    out.write(line)
    # use realine() to read next line
    line = f.readline()

f.close()
out.close()


##########################
#BASH VERSION HERE
##########################

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
