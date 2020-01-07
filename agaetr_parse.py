#!/usr/bin/python3

#https://alvinalexander.com/python/python-script-read-rss-feeds-database
#super props

import feedparser
import time
import string
from time import strftime,localtime
from subprocess import check_output
import sys
import json
from bs4 import BeautifulSoup
from pprint import pprint
import configparser
import os
from os.path import expanduser
from appdirs import *
from pathlib import Path
import shutil

########################################################################
# Defining configuration locations and such
########################################################################

appname = "agaetr"
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
ini = os.path.join(configdir,'agaetr.ini')
db = os.path.join(datadir,'posts.db')
tmp = os.path.join(cachedir,'posts.db')

Path(db).touch()
Path(tmp).touch()
########################################################################
# Have we already posted this? (our "db" is a flat file, btw)
########################################################################
def post_is_in_db(title):
    with open(db, 'r') as database:
        for line in database:
            if title in line:
                return True
    return False

########################################################################
# Parsing that feed!
########################################################################
def parse_that_feed(url,sensitive,CW,GCW):

    feed = feedparser.parse(url)

    for post in feed.entries:

        # if post is already in the database, skip it
        # TODO check the time

        title = post.title.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
        post.title = post.title.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
        itemurl = post.link
        # cleaning up descriptions and summaries.  Boy, are they trash.
        if hasattr(post, 'description'):
            if "Permalink" not in (str.lower(post.description)):
                post_description = post.description
                post_description = post_description.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
                splitter = post_description.split()
                post_description =" ".join(splitter)
        else:
            if hasattr(post, 'summary'):
                if "Permalink" not in (str.lower(post.summary)):
                    post_description = post.summary
                    post_description = post_description.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
                    splitter = post_description.split()
                    post_description =" ".join(splitter)

        # While this avoids errors from the TT-RSS feed, it provides a bad date
        # And since the python module pulls in the feed directly, hence the need
        # for our preprocessor. (And probably also a quick way to see if it's
        # been updated, too.)
        date_published = localtime()  
        thetime=time.strftime("%Y%m%d%H%M%S",localtime())
        
        
        if hasattr(post, 'published_parsed'):
            date_parsed = post.published_parsed
            thetime=time.strftime("%Y%m%d%H%M%S",date_parsed)
        if hasattr(post, 'post.published'):
            date_published = post.published
            thetime=time.strftime("%Y%m%d%H%M%S",date_published)
        if hasattr(post, 'post.updated'):
            date_published = post.updated
        
        if not post_is_in_db(title):      
            f = open(db, 'a')
            tags = []
            hashtags = []

            if hasattr(post, 'tags'):
                i = 0

                while i < len(post.tags):
                    if "uncategorized" not in (str.lower(post.tags[i]['term'])):
                        if "onetime" not in (str.lower(post.tags[i]['term'])):
                            if "overnight" not in (str.lower(post.tags[i]['term'])):
                                if "post" not in (str.lower(post.tags[i]['term'])):
                                    hashtags.append('#%s' % str.lower(post.tags[i]['term']))
                    i += 1

                if GCW:
                    tags.append('%s' % str.lower(GCW))
                i = 0
                while i < len(post.tags):
                    if "uncategorized" not in (str.lower(post.tags[i]['term'])):
                        if "onetime" not in (str.lower(post.tags[i]['term'])):
                            if "overnight" not in (str.lower(post.tags[i]['term'])):
                                if "post" not in (str.lower(post.tags[i]['term'])):
                                    if (str.lower(post.tags[i]['term'])) not in tags: 
                                        tags.append('%s' % str.lower(post.tags[i]['term']))
                    i += 1

            #Do we always have CW on this feed?
            if CW == "no":
                cwmarker = 0
            else:
                cwmarker = 1

            if hasattr(post, 'tags'):
                for d in tags:
                    if d in ContentWarningString:
                        cwmarker += 1

            # double checking with title as well
            bob = str.lower((', '.join(tags)) + ' ' + post.title)
            for d in ContentWarningString.split():
                if d in bob:
                    cwmarker += 1
                    tags.append('%s' % str.lower(d))
                    

            #if cwmarker > 0:
            #    print("cw: " + str.lower(', '.join(tags)))
            #print(tags)
            imgalt=None
            imgurl=None
            # Look for image in media content first
            if 'media_content' in post:
                mediaContent=post.media_content
                for item in post.media_content:
                    amgurl = item['url'].split('?')
                    if amgurl[0].endswith("jpg"):
                        imgurl = amgurl[0]
                        imgalt = post.title
                        break
            else:
                # Finding image in the html
                soup = BeautifulSoup((post.content[0]['value']), 'html.parser')
                imgtag = soup.find("img")

                # checking for tracking images
                if soup.find("img"):
                    if imgtag.has_attr('width'):
                        if (int(imgtag['width']) > 2):    
                            imgurl = imgtag['src']
                            # seeing if there's an alt title for accessibility
                            if imgtag.has_attr('alt'):
                                imgalt = imgtag['alt']
                            else: 
                                if imgtag.has_attr('title'):
                                    imgalt = imgtag['title']
                                else:    
                                    imgalt = None
                            #checking for empty strings
                            imgalt = imgalt.strip()
                            if not imgalt:
                                imgalt = post.title
                               
            #put post in db?
            #how bring down img? at posting time?
            print("Adding " + post.title)
            #print(post.link)
            #print (str.lower(''.join(hashtags))
            
            if cwmarker > 0:
                f.write(thetime + "|" + post.title + "|" + post.link + "|" + str.lower(', '.join(tags)) + "|" + str(imgalt) + "|" + str(imgurl) + "|" + str.lower(' '.join(hashtags)) + "|" + str(post_description) + "\n") 
            else:
                f.write(thetime + "|" + post.title + "|" + post.link + "|" + "|" + str(imgalt) + "|" + str(imgurl) + "|" + str.lower(' '.join(hashtags)) + "|" + str(post_description) + "\n")
            
            f.close
        else:
            print("We've already got one")
    return


########################################################################
# Read ini section
########################################################################

config = configparser.ConfigParser()
config.read(ini)
sections=config.sections()

########################################################################
# Begin loop over feedlist
########################################################################
ContentWarningList = config['DEFAULT']['filters']
ContentWarningString = str.lower(config['DEFAULT']['filters'])
for x in sections:
    if "feed" in (str.lower(x)):
        feed=config[x]['url']
        feed_sensitive=config[x]['sensitive']
        feed_CW=config[x]['ContentWarning']
        feed_GlobalCW=config[x]['GlobalCW']
        parse_that_feed(feed,feed_sensitive,feed_CW,feed_GlobalCW)



shutil.copyfile(db,tmp)

infile = open(tmp,'r')
lines = infile.readlines()
infile.close
out = open(db, 'w')
for line in sorted(lines, key=lambda line: line.split()[0]):
    out.write(line)
out.close
os.remove(tmp)

exit()


# super first - check the url against our "db"
# first, check the dict of tags against a list
# determine if sensitive and/or CW based on user preference
#   Options - by keyword (title, tags)
#           - always
#           - never
# second, create a cachedir (because we need that picture)
# third, write the posting strings and the image to the cachedir
            # TODO: Take out null tags like overnight and uncategorized

# WILL NEED AWK/SED PREFILTER, uuugh
# Still, doing it in python seems to be a pain, and a quick bash script would
# allow others to fix it to their own satisfaction. Also, it's got to be 
# feed by feed, etc.  And some of these things needing replaced are multiline,
# which a python sed implementation isn't able to handle afaik.

# Article Note to summary
# color : #9a8c59;">Article note: That is a lot of Fresh Air.</div><div>

# summary remove <div class="more-link-wrapper"> until</description>
# sed -e 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g' ideatrash.xml > filename
# <updated> -> <pubDate> (and closing tags)
#cat ttrss.xml | sed 's@<updated>@<pubDate>@g' | sed 's@</updated>@</pubDate>@g' > parsed_ttrss.xml
