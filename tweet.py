#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
from __future__ import division

##
# Originally derived from a script by Benjamin D. McGinnes, licensed 
# under the Apache 2.0 license
#
# Requirements:
#
# * Python 3.4 or later.
# Usage:  
# tweet.py --message "Thing to tweet" --file /path/to/file/to/tweet
##

import os
import os.path
import sys
import argparse
from twython import Twython, TwythonError

APP_KEY = ""
APP_SECRET = ""
OAUTH_TOKEN = ""
OAUTH_TOKEN_SECRET = ""


twitter = Twython(APP_KEY, APP_SECRET, OAUTH_TOKEN, OAUTH_TOKEN_SECRET)
cred = twitter.verify_credentials()

l = len(sys.argv)

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('-f', '--file', action='store',dest='media_fn', nargs='+')
parser.add_argument('-t', '--tweet', action='store',dest='message', nargs='+')
args = parser.parse_args()

print ('Media file is ', args.media_fn)
print ('Message is ', args.message)

reply_id = None
twid = None

message = args.message
media_fn = args.media_fn  


if media_fn is not None:
    mfiles = media_fn[0].split()
    lm = len(mfiles)
    mfid = []
    for i in range(lm):
        if os.path.isfile(os.path.realpath(mfiles[i])) is True:
            mediaf = os.path.realpath(mfiles[i])
        elif os.path.isfile(os.path.realpath("InputFiles/{0}".format(mfiles[i]))) is True:
            mediaf = os.path.realpath("InputFiles/{0}".format(mfiles[i]))
        else:
            mediaf = None

        if mediaf is None:
            mfid.append(mediaf)
        else:
            mf = open(mediaf, "rb")
            response = twitter.upload_media(media=mf)
            mfid.append(response["media_id"])
else:
    mfid = None

if len(message) < 1 and twid is None and mfid is None:
    mesg = None
elif len(message) < 1 and twid is None and mfid is not None:
    mesg = "."
elif len(message) < 1 and twid is not None and mfid is not None:
    users = []
    hashtags = []
    try:
        tweet = twitter.show_status(id=twid)
        user1 = "@"+tweet["user"]["screen_name"]
        users.append(user1)
        rtweet = tweet["text"]
        rtword = rtweet.split()
        for i in range(len(rtword)):
            if rtword[i].startswith("@") is True:
                users.append(rtword[i])
            elif rtword[i].startswith("#") is True:
                hashtags.append(rtword[i])
            else:
                pass
        ustr = " ".join(users)
        hstr = " ".join(hashtags)
        mesg = "{0} {1}".format(ustr, hstr)
    except TwythonError as e:
        print(e)
        mesg = "."
else:
    mesg = message

    
if mesg is not None and twid is None and mfid is None:
    try:
        twitter.update_status(status=mesg)
    except TwythonError as e:
        print(e)
elif mesg is not None and twid is not None and mfid is None:
    try:
        twitter.update_status(status=mesg, in_reply_to_status_id=twid)
    except TwythonError as e:
        print(e)
elif mesg is not None and twid is None and mfid is not None:
    try:
        twitter.update_status(status=mesg, media_ids=mfid)
    except TwythonError as e:
        print(e)
elif mesg is not None and twid is not None and mfid is not None:
    try:
        twitter.update_status(status=mesg, media_ids=mfid,
                              in_reply_to_status_id=twid)
    except TwythonError as e:
        print(e)
elif mesg is None and twid is None and mfid is not None:
    try:
        twitter.update_status(status="", media_ids=mfid)
    except TwythonError as e:
        print(e)
elif mesg is None and twid is not None and mfid is not None:
    try:
        twitter.update_status(status="", media_ids=mfid,
                              in_reply_to_status_id=twid)
    except TwythonError as e:
        print(e)
else:
    print("""
As with all things in this world, you get out of it what you put in
and you put in nothing.
""")
