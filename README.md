# agaetr

A modular system to take a list of RSS feeds, process them, and send them to 
social media with images, content warnings, and sensitive image flags when 
available. 

![agaetr logo](https://raw.githubusercontent.com/uriel1998/agaetr/master/agaetr_logo.png "logo")

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [Installation](#4-installation)
 5. [Services Setup](#5-services-setup)
 6. [Feeds Setup](#6-feeds-setup)
 7. [Feed Preprocessing](#7-feed-preprocessing)
 8. [Feed Options](#8-feed-options)
 9. [Usage](#9-usage)
 10. [TODO](#10-todo)

***

## 1. About

`agaetr` is a modular system made up of several small programs designed to take 
input (particularly RSS feeds) and then share them to various social media outputs.

This system is designed for *single user* use, as API keys are required.

Currently works well with feeds from [dlvr.it](https://dlvrit.com/) 
and [shaarli](https://github.com/shaarli/Shaarli) instances. A preprocessing 
script is also available (with examples) for fixing a few things with WordPress 
and TT-RSS "published articles" feeds.  It can also *deobfuscate* incoming 
links and optionally shorten outgoing links.

The modular structure is specifically designed so that it should be easy to 
create a new module for additional services, as it relies on other programs 
to do most of the posting.

`agaetr` is an anglicization of ágætr, meaning "famous".


## 2. License

This project is licensed under the MIT license. For the full license, see `LICENSE`.

## 3. Prerequisites

* Python 3
* Bash

These are probably already installed or are easily available from your distro:
* [wget](https://www.gnu.org/software/wget/)
* [awk](http://www.gnu.org/software/gawk/manual/gawk.html)
* [grep](http://en.wikipedia.org/wiki/Grep)
* [curl](http://en.wikipedia.org/wiki/CURL)

You will need some variety of posting mechanism. Currently written are:

* Mastodon: [toot](https://github.com/ihabunek/toot/)
* Twitter [twython](https://github.com/ryanmcgrath/twython) and [twython-tools](https://github.com/adversary-org/twython-tools) - **IMPORTANT- SEE BELOW**
* Twitter [oysttyer](https://github.com/oysttyer/oysttyer)
                

Ideally, you should create a virtualenv for this project, as there are a number 
of python dependencies.  Instructions on how to do that are beyond the scope of 
this document.  It is assumed that you have created and activated the 
virtualenv henceforth.

## 4. Installation

* `mkdir -p $HOME/.config/agaetr`
* `mkdir -p $HOME/.local/agaetr`
* Edit `agaetr.ini` (see instructions below)
* `cp $PWD/agaetr.ini $HOME/.config/agaetr`
* `sudo chmod +x $PWD/agaetr_parse.py`
* `sudo chmod +x $PWD/agaetr_send.sh`
* (If using `tweet.py`) `sudo chmod +x $PWD/tweet.py`
* `pip install -U twython --user`
* `pip install -U appdirs --user`
* `pip install -U configparser --user`
* `pip install -U beautifulsoup4 --user`
* `pip install -U feedparser --user`

Any service you would like to use needs to have a symlink made from the "avail" 
directory to the "enabled" directory. For example:

* `ln -s $PWD/short_avail/yourls.sh $PWD/short_enabled/yourls.sh`

You may use as many "out" options as you care to; choose 0 or 1 shortening 
services.

## 5. Services Setup

### Ones Not Covered Here

I tried to write the functions here in a way so that it should be simple to 
add new ones if you like other tools or other services come along (for example, 
[jediverse](https://jediverse.com/) or if there's a client to post to an IRC 
channel, etc.

If you create one for another service, please contact me so I can merge it in 
(this repository is mirrored multiple places).

### murls  

Murls is a free service and does not require an API key. 

### bit.ly  

**IMPORTANT NOTE** The bit.ly api is changing in March 2020 and is getting 
more complex; I've not updated/fixed this yet.

If you are using bit.ly, you will need a username and bit.ly API key.
Place the values of your login and API key into `agaetr.ini`.
bitly_login = 
bitly_api = 

### YOURLS  

Go to your already functional YOURLS instance.  Get the API key from 
Place the URL of your instance and API key into `agaetr.ini`.
yourls_api=
yourls_site = 

### Oysttyer  

Download the script and follow its setup instructions
Place the location of the binary into `agaetr.ini`.

### Shaarli (output)

https://github.com/shaarli/python-shaarli-client
Make sure you set up the configuration file!

### Wallabag (output)

Get the appropriate binary release and install 
https://github.com/Nepochal/wallabag-cli/blob/master/docs/installation.md
https://github.com/Nepochal/wallabag-cli/releases
https://github.com/Nepochal/wallabag-cli
run wallabag config

Note that shorteners and wallabag don't get along all the time.


### toot  

`pip3 install toot`
Place the location of the binary into `agaetr.ini`.

### twython (sort of)  

In this archive are two files - `tweet.py` and `tweet.patch` - that require a 
little explanation. I did not need the full functionality of twython-tools, 
and in fact, had a bit of a problem getting the gpg encoding of my app keys 
to work. Further, the functionality I *did* want, that is posting an 
image to Twitter, was always *interactive* when I wanted to enter the 
file on the command line. 

So I (thank you Apache2 license) ripped out the authentication portions and 
hardcoded them, ripped out all the interactive bits, and remade the Twython-tools 
program `tweet-full.py` into `tweet.py`. 

If you wish to see the difference, `tweet.patch` is included for you to verify 
my changes to the code.

You must register a [Twitter application](https://apps.twitter.com) and get 
**user** API codes and type them manually into `tweet.py`.

Place the location of the binary into `agaetr.ini`.

*Optional* - Put the full path to the virtual environment's python interpreter 
in for the shebang for `tweet.py`, as in: `#!/path/to/home/agaeter_venv/bin/python` . I had no luck with this;
I ended up having to install it globally.

APP_KEY = ""
APP_SECRET = ""
OAUTH_TOKEN = ""
OAUTH_TOKEN_SECRET = ""

## 6. Feeds Setup

Information about your feeds goes into `agaetr.ini`.  Each feed is marked by a
header line `[Feed#]` with a different number for each feed.

If a feed is being preprocessed (see below), you can put the resulting 
filename directly into `agaetr.ini`.  

[Feed1]
url = /home/steven/agaetr/ideatrash_parsed.xml
sensitive = yes
ContentWarning = no
GlobalCW = 

[Feed2]
url = https://ideatrash.net/feed
sensitive = yes
ContentWarning = yes
GlobalCW = ideatrash

## 7. Feed Preprocessing

If you have a feed with some unruly elements - such as the "Read more..." that 
Wordpress loves to put in my own feed, or how the "published articles" feed from 
tt-rss uses `<updated>` instead of `<pubDate>`, there is an example bash 
script to fix both those problems with `sed`.  As you can see above, you can 
specify a filename *OR* an URL for the feed location. This allows the use of 
the preprocessor without changing anything else.

Please note that if you're importing a Shaarli feed, you will probably want to 
toggle "RSS direct links" in the Preferences menu, otherwise it links directly 
to your Shaarli, not to the thing your Shaarli is pointing at.

## 8. Feed Options

There are two places to configure feed options in `agaetr.ini`. In the 
default block, you can define the default options. For social media accounts 
that support content warnings and sensitive image markers (like Mastodon) you 
can configure if images are "sensitive" by default, whether the posts from `agaetr` 
are marked with content warning by default, and what strings (in the post title 
or tag) will *always* trigger the content warning, 

If you need ideas for what tags/terms make good content warnings, the file 
`cwlist.txt` is included for your convenience. Because of how it matches, a 
filter of "abuse" should catch "child abuse" and "sexual abuse", etc.

Note: Images are marked as sensitive if the content warning is triggered.

Sensitive = no
ContentWarning = no
GlobalCW = From feeds, possibly sensitive
# These ALWAYS trigger a content warning
filters =
#filters = politics blog sex bigot supremacist nazi climate

Then, in each feed's configuration, you can choose the default for *that feed*. 
For example, in *Feed1* below, images are marked sensitive, but there is *not* 
a content warning for any items in the feed.  

In *Feed2* below, all images are marked sensitive and all posts are marked with a 
content warning of "ideatrash".  It will also mark the content warning with 
any other tags the post may have.

In *Feed3* below, images are only marked sensitive if they are triggered by a 
content warning (from the "filter" line in the *Default* section), otherwise 
there are no content warnings and images are presented normally.

[Feed1]
url = /home/steven/agaetr/ideatrash_parsed.xml
sensitive = yes
ContentWarning = no
GlobalCW = 

[Feed2]
url = https://ideatrash.net/feed
sensitive = yes
ContentWarning = yes
GlobalCW = ideatrash

[Feed2]
url = https://ideatrash.net/feed
sensitive = no
ContentWarning = yes
GlobalCW = 

## 9. Usage

* (Optional) Call `rss_preprocessor.sh`.
* `python agaetr_parse.py` to pull down new articles from feeds.
* `agaetr_send.sh` to send *a* post to the activated social media services

You will probably wish to add `agaetr_send.sh` to your crontab.

## 10. TODO

* Create a requirements.txt for pip to simplify installation.
* test INBOUND trakt.tv, deviant art
* Wallabag in RSS seems to be broken, not sure why.
* Archive of sent links?
* Test CW creation from tags
* Test CW without a global CW
* Test install completely on clean machine to make sure I have it right, lol
* Clean up documentation
* Ensure that send exits cleanly if there's no articles !!
* Ensure parser doesn't choke if there's a newline at the end of the posts.db file
* Add "wobble" to time of sending with `agaetr_send`.  (e.g. +- 5min)
* If hashtags are in description or title, make first occurance a hashtag
* Create some kind of homespun CW for Twitter, etc
* Out posting for Facebook (pages, at least), Pleroma, Pintrest, IRC, Insta
