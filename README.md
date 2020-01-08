# agaetr

A modular system to take a list of RSS feeds, process them, and send them to 
social media with images, content warnings, and sensitive image flags when 
available. 

![agaetr logo](https://raw.githubusercontent.com/uriel1998/agaetr/master/agaetr-open-graph.png "logo")

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
 10. [Other Files](#10-other-files)
 11. [TODO](#11-todo)

***

## 1. About

`agaetr` is a modular system made up of several small programs designed to take 
input (particularly RSS feeds) and then share them to various social media outputs.

This system is designed for *single user* use, as API keys are required.

Tested with feeds from:

* [dlvr.it](https://dlvrit.com/) 
* [shaarli](https://github.com/shaarli/Shaarli) instances (see note below)
* [Wordpress](https://wordpress.org/) (with preprocessing script)
* [TT-RSS](https://tt-rss.org/) (with preprocessing script)
* [Trakt.tv](https://trakt.tv) 
* [DeviantArt](https://www.deviantart.com)
* [YouTube](https://youtube.com) (particularly public playlists, like favorites)

The preprocessing script is available (with examples) for fixing a few things 
with WordPress and TT-RSS "published articles" feeds.  

It can also *deobfuscate* incoming links and optionally shorten outgoing links.

This was created because pay services are expensive, and other options are 
either limited or subject to frequent bitrot.

The modular structure is specifically designed so that it should be easy to 
create a new module for additional services, as it relies on other programs 
to do most of the posting. Therefore, if one posting tool dies, another can be 
found and (relatively) easily swapped in without changing your whole setup.

`agaetr` is an anglicization of ágætr, meaning "famous".


## 2. License

This project is licensed under the Apache License. For the full license, see `LICENSE`.

## 3. Prerequisites

These are probably already installed or are easily available from your distro on
linux-like distros:  

* [python3](https://www.python.org)  
* [bash](https://www.gnu.org/software/bash/)  
* [wget](https://www.gnu.org/software/wget/)  
* [awk](http://www.gnu.org/software/gawk/manual/gawk.html)  
* [grep](http://en.wikipedia.org/wiki/Grep)  
* [curl](http://en.wikipedia.org/wiki/CURL)  

You will need some variety of posting mechanism and optionally an URL 
shortening mechanism. See [Services Setup](#5-services-setup) for details.

It is strongly recommended to create a virtualenv for this project; the 
installation instructions are written with this in mind.

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

* `pip install -r requirements.txt` 

OR

* `pip install appdirs`  
* `pip install configparser`  
* `pip install beautifulsoup4`  
* `pip install feedparser`  
* `pip install requests`

Any service you would like to use needs to have a symlink made from the "avail" 
directory to the "enabled" directory. For example:

* `ln -s $PWD/short_avail/yourls.sh $PWD/short_enabled/yourls.sh`

You may use as many "out" options as you care to; choose 0 or 1 shortening 
services.

## 5. Services Setup

### Services Not Covered Here

One of the reason there are multiple different example service wrappers 
(and that they are written in pretty straightforward BASH scripting) 
is so that future users (including myself) can use them as templates or 
examples for other tools or new services with as little fuss as possible 
and without requiring a great deal of knowledge on the part of the user. 

If you create one for another service, please contact me so I can merge it in 
(this repository is mirrored multiple places).


### Shorteners

#### murls  

Murls is a free service and does not require an API key. 

#### bit.ly  

**IMPORTANT NOTE** The bit.ly api is changing in March 2020 and is getting 
more complex; I've not updated/fixed this yet.

If you are using bit.ly, you will need a username and bit.ly API key.
Place the values of your login and API key into `agaetr.ini`.

`bitly_login =`  
`bitly_api =`  

#### YOURLS  

Go to your already functional YOURLS instance.  Get the API key from 
Place the URL of your instance and API key into `agaetr.ini`.  

`yourls_api =`  
`yourls_site =`  

### Outbound parsers

* Mastodon:
* Twitter  - **IMPORTANT- SEE BELOW**
* Twitter 
* Shaarli 
* Wallabag                 

Note that each service has its own line in `agaetr.ini`.  Leave blank any 
you are not using; adding additional services should follow the pattern shown.  

#### Twitter via Oysttyer  

Install and set up [oysttyer](https://github.com/oysttyer/oysttyer). Place the 
location of the binary into `agaetr.ini`.  

While `Oysttyer` is by far the easier to set up, it does *not* allow you to 
specify the image that is tweeted.  For that, you need `twython`, below.  

### Shaarli (output)

Install and set up the [Shaarli-Client](https://github.com/shaarli/python-shaarli-client). 
Make sure you set up the configuration file for the client properly. Place the 
location of the binary into `agaetr.ini`.

#### Wallabag (output)

Install and set up [Wallabag-cli](https://github.com/Nepochal/wallabag-cli). 
Place the location of the binary into `agaetr.ini`.

Note that shorteners and wallabag don't get along all the time.

#### Mastodon via toot  

Install and set up [toot](https://github.com/ihabunek/toot/).  Place the 
location of the binary into `agaetr.ini`.

#### Twitter using twython 

This one is a little more complicated, but this is the Twitter client that 
will post images directly to Twitter.  If this is too complicated, use 
`oysttyer` above.

Install [twython](https://github.com/ryanmcgrath/twython) - preferably in your 
virtual environment that `agaetr` is in via `pip install -U twython`.

In this archive are two files - `tweet.py` and `tweet.patch` - that require a 
little explanation. I did not need the full functionality of [twython-tools](https://github.com/adversary-org/twython-tools), 
and in fact, had a bit of a problem getting it working properly. Further, the 
functionality I *did* want - posting an image to Twitter - was always 
*interactive* when I wanted to enter the file on the command line. 

So I (thank you Apache2 license) ripped out the authentication portions and 
hardcoded them, ripped out all the interactive bits, and remade the Twython-tools 
program `tweet-full.py` into `tweet.py`. 

If you wish to see the difference, `tweet.patch` is included for you to verify 
my changes to the code.

You must register a [Twitter application](https://apps.twitter.com) and get 
**user** API codes and type them manually into `tweet.py`.

`APP_KEY = ""`  
`APP_SECRET = ""`  
`OAUTH_TOKEN = ""`  
`OAUTH_TOKEN_SECRET = ""`  

Place the location of the binary into `agaetr.ini`.

## 6. Feeds Setup

Information about your feeds goes into `agaetr.ini`.  Each feed is marked by a
header line `[Feed#]` with a different number for each feed. 

If a feed is being preprocessed (see below) or you have the RSS as an 
XML file, you can put the filename directly into `agaetr.ini`.  The options 
are explained in [Feed Options](#8-feed-options) below.

For example:

```
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

```

## 7. Feed Preprocessing

While RSS is *supposed* to be a standard... it isn't. Too often there are 
unusual or irregular elements in an RSS feed.

While I've tried to make some of the more popular "odd" feeds - like YouTube 
and DeviantArt - work properly inside of `agaetr_parse.py`, I cannot check 
or code for every possibility. 

If you have a feed with some unruly elements - such as the "Read more..." that 
Wordpress loves to put in my own feed, or how the "published articles" feed from 
tt-rss uses `<updated>` instead of `<pubDate>`, there is an example BASH 
script to fix both those problems with `sed`.  

Again, you can specify the output filename for the feed location in 
`agaetr.ini`. This allows the use of the preprocessor without changing 
anything else.

This isn't meant to be a comprehensive "fix" so much as an example to 
help get you started with your own unruly feeds.

### Note about Shaarli feeds

Please note that if you're importing a Shaarli feed, you will probably want to 
toggle "RSS direct links" in the Preferences menu, otherwise it links directly 
to your Shaarli, not to the thing your Shaarli is pointing at.

## 8. Feed Options

There are two places to configure feed options in `agaetr.ini`. 

In the default block, you can define the (duh) default options. For 
social media accounts that support content warnings and sensitive image 
markers (like Mastodon) you can configure if images are "sensitive" by 
default, whether the posts from `agaetr` are marked with content warning 
by default, and what strings (in the post title or tags) will *always* 
trigger the content warning.

If you need ideas for what tags/terms make good content warnings, the file 
`cwlist.txt` is included for your convenience. Because of how it matches, a 
filter of "abuse" should catch "child abuse" and "sexual abuse", etc.

*Note*: Keywords searched for **are used as the content warning**. So if 
you are trying to content warning the word "Trump", it will show up as 
the content warning. You may wish to use terms like "politics" instead. 
I hope to create a better automatic content warning system later.

*Note*: Images are marked as sensitive if the content warning is triggered.

```
Sensitive = no
ContentWarning = no
GlobalCW = From feeds, possibly sensitive
# These ALWAYS trigger a content warning
filters =
#filters = politics blog sex bigot supremacist nazi climate
```

In each feed's configuration, you can choose the default for *that feed*. 
For example, in *Feed1* below, images are marked sensitive, but there is *not* 
a content warning for any items in the feed.  

In *Feed2* below, all images are marked sensitive and all posts are marked with a 
content warning of "ideatrash".  It will also mark the content warning with 
any other tags the post may have.

In *Feed3* below, images are only marked sensitive if they are triggered by a 
content warning (from the "filter" line in the *Default* section), otherwise 
there are no content warnings and images are presented normally.

```
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

[Feed3]
url = https://ideatrash.net/feed
sensitive = no
ContentWarning = yes
GlobalCW = 

```

## 9. Usage

### IMPORTANT NOTE ABOUT CRON

**If you run `agaetr` as a cron job, ensure that the cron job is 
run as the user (and with the environment) you used to set up the 
online services.**  


* (Optional) Call `rss_preprocessor.sh`.
* `agaetr_parse.py` to pull down new articles from feeds.
* `agaetr_send.sh` to send *a* post to the activated social media services

Seriously, once everything is set up, that's it. You'll probably want to 
put these into cronjobs. 

## 10. Other files

There are other files in this repository:

* `unredirector.sh` - Used by `agaetr` to remove redirections and shortening.
* `standalone_sender.sh` - Working on this to use the `agaetr` framework without RSS feeds; not ready for use yet.  

## 11. TODO

### Roadmap:

* Archive of sent links - 0.9

### Someday/Maybe:

* Create a full on installation script including virtualenv and installing stuff?
* Better content warning system where series of words can trigger "uspol" for example
* test INBOUND wallabag - seems to be broken?
* In and out - Instagram? 
* Per feed output selectors (though that's gonna be a pain)
* Test CW without a global CW
* Check that send exits cleanly if there's no articles !!
* Check parser doesn't choke if there's a newline at the end of the posts.db file
* Add "wobble" to time of sending with `agaetr_send`.  (e.g. +- 5min)
* If hashtags are in description or title, make first occurance a hashtag
* Create some kind of homespun CW for Twitter, etc
* Out posting for Facebook (pages, at least), Pleroma, Pintrest, IRC, Instagram
