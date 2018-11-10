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

    print('Building base args for posters')
    tweetlist = []
    tweetlist.append('--tweet "')
    tweetlist.append(linetitle)
    tweetlist.append(' ')
    tweetlist.append(linelink)
    tweetlist.append(' ')       
    tweetlist.append(linehashtags)
    tweetlist.append('"')

    mastolist = []
    mastolist.append('post ')
    if linecw is not None:
        mastolist.append('--spoiler-text "')
        mastolist.append(linecw)
        mastolist.append('" ')
    mastolist.append('"')
    mastolist.append(linetitle)
    mastolist.append(' ')
    mastolist.append(linelink)
    mastolist.append(' ')
    mastolist.append(linehashtags)
    mastolist.append('"')
    
    #getting image
    a = urlparse(lineimgurl)
    imgfilename = os.path.basename(a.path)
    lineimgloc = os.path.join(cachedir,imgfilename)
    print('Beginning file download with wget module')
    wget.download(lineimgurl, lineimgloc) 
    if os.path.isfile(lineimgloc):
        tweetlist.append(' --file ')
        tweetlist.append(lineimgloc)
        mastolist.append(' --media ')
        mastolist.append(lineimgloc)
        if linecw is not None:
            mastolist.append(' --sensitive')
    tweetstring = ''.join(tweetlist)
    tootstring = ''.join(mastolist)
    print(tweetstring)
    print(tootstring)       
#        subprocess.call(['ls','--message','-a'])
        ###THIS IS FROM THE BASH VERSION I NEED TO CHANGE IT
    
 
########################################################################
# Begin loop over feedlist
########################################################################

Loops = config['DEFAULT']['ArticlesPerRun']
Loops = int(Loops)
LoopsPerformed = 0

# Open the file with read only permit
f = open(db)
while LoopsPerformed < Loops:
    line = f.readline()
    line = line.rstrip()
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

#Clean

#rm -rf "$TEMPDIR"
#rm "$TEMPFILE"
