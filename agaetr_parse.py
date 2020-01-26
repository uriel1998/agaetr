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
import requests
import urllib.parse

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
posteddb = os.path.join(datadir,'posted.db')         
tmp = os.path.join(cachedir,'posts.db')

Path(posteddb).touch()
Path(db).touch()
Path(tmp).touch()
########################################################################
# Have we already posted this? (our "db" is a flat file, btw)
# Added in check for the posted db
########################################################################
def post_is_in_db(title):
    with open(db, 'r') as database:
        for line in database:
            if title in line:
                return True
    with open(posteddb, 'r') as database2:
        for line1 in database2:
            if title in line1:
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
            if "permalink" not in (str.lower(post.description)):
                post_description = post.description
                post_description = post_description.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
                splitter = post_description.split()
                post_description =" ".join(splitter)
                post_description =BeautifulSoup(post_description, "lxml").text
            else:
                post_description = ""
        else:
            if hasattr(post, 'summary'):
                if "permalink" not in (str.lower(post.summary)):
                    post_description = post.summary
                    post_description = post_description.replace('\n', ' ').replace('\r', '').replace('<p>', '').replace('</p>', '').replace('|', ' ')
                    splitter = post_description.split()
                    post_description =" ".join(splitter)
                    post_description =BeautifulSoup(post_description, "lxml").text
                else:
                    post_description = ""
        
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
                                    post.tags[i]['term'] = post.tags[i]['term'].replace(':',' ').replace('|', ' ').replace('/',' ').replace('\\',' ').replace('  ',' ').replace(' ','-')
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
                                        post.tags[i]['term'] = post.tags[i]['term'].replace('|', ' ').replace('/',' ').replace('\\',' ')
                                        tags.append('%s' % str.lower(post.tags[i]['term']))
                    i += 1

            #Do we always have CW on this feed?
            if CW == "no":
                cwmarker = 0
                ContentWarningString = ""
            else:
                cwmarker = 1
                ContentWarningString = feed_GlobalCW
            
            
            #TODO
            #This is where to put our new CW loop from ini
            #pull in from ini  ( I think I can axe this next line)
            #hoping to re-loop through ini and pull in cw# sections
            for x in sections:
                if "cw" in (str.lower(x)):
                    ContentWarningList = str.lower(config['DEFAULT']['filters'])
                    keyword=config[x]['keyword']
                    ContentWarningList = ContentWarningList + str.lower(config[x]['matches'])


                    if hasattr(post, 'tags'):
                        for d in tags:
                            if d in ContentWarningList.split():
                                cwmarker += 1
                                ContentWarningString = ContentWarningString + " " + keyword
                    # double checking with title as well
                    bob = str.lower((', '.join(tags)) + ' ' + post.title)
                    for d in ContentWarningList.split():
                        if d in bob.split():
                            cwmarker += 1
                            ContentWarningString = ContentWarningString + " " + keyword

            imgalt=None
            imgurl=None
            # Look for image in media content first
            if 'media_content' in post:
        
                # Trying the sleep function here in case there's flood protection on 
                # the server we're checking images from

                time.sleep(2)
                mediaContent=post.media_content
                for item in post.media_content:
                    # making sure it's not flash/video from Youtube/Vimeo
                    if 'type' in item:
                        if "flash" in (item['type']): 
                            #print(item['type'])
                            if 'media_thumbnail' in post:
                                mediaContent=post.media_thumbnail
                                for item in post.media_thumbnail:
                                    amgurl = item['url'].split('?')
                    
                                    if amgurl[0].endswith("jpg"):
                                        r = requests.head(amgurl[0], timeout=10)
                                        if (int(r.status_code) == 200):
                                            imgurl = amgurl[0]
                                        else:
                                            imgurl = item['url']
                                        imgalt = post.title
                                        break
                    amgurl = item['url'].split('?')
                    if amgurl[0].endswith("jpg"):
                        r = requests.head(amgurl[0], timeout=10)
                        if (int(r.status_code) == 200):
                            imgurl = amgurl[0]
                        else:
                            imgurl = item['url']
                        imgalt = post.title
                        break
            else:
                # Finding image in the html
                if 'content' in post:
                    soup = BeautifulSoup((post.content[0]['value']), 'html.parser')
                    imgtag = soup.find("img")
                    #print(imgtag)
                else:
                    soup = BeautifulSoup(urllib.parse.unquote(post.description), 'html.parser')
                    imgtag = soup.find("img")
                    #print(imgtag)
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
                    else:
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
                        if not imgalt:
                            imgalt = post.title
                        else:
                            imgalt = imgalt.strip()
            print("# Adding " + post.title)
            
            if cwmarker > 0:  
                words = ContentWarningString.split()
                ContentWarningString = (",".join(sorted(set(words), key=words.index)))
                HashtagsString = str.lower(' '.join(hashtags))
                words2 = HashtagsString.split()
                HashtagsString = (" ".join(sorted(set(words2), key=words2.index)))
                #f.write(thetime + "|" + post.title + "|" + post.link + "|" + str.lower(', '.join(tags)) + "|" + str(imgalt) + "|" + str(imgurl) + "|" + str.lower(' '.join(hashtags)) + "|" + str(post_description) + "\n") 
                f.write(thetime + "|" + post.title + "|" + post.link + "|" + str.lower(ContentWarningString) + "|" + str(imgalt) + "|" + str(imgurl) + "|" + HashtagsString + "|" + str(post_description) + "\n") 
            else:
                f.write(thetime + "|" + post.title + "|" + post.link + "|" + "|" + str(imgalt) + "|" + str(imgurl) + "|" + HashtagsString + "|" + str(post_description) + "\n")
            
            f.close
        else:
            print("## Already have " + post.title)
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
#TODO - fix this
ContentWarningList = config['DEFAULT']['filters']
ContentWarningString = str.lower(config['DEFAULT']['GlobalCW'])
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
