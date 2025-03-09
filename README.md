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
 9. [Advanced Content Warning](#9-advanced-content-warning)
 10. [Usage](#10-usage)
 11. [Other Files](#11-other-files)
 12. [TODO](#12-todo)

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
* [UPI](https://rss.upi.com/news/news.rss)

`agaetr` can also *deobfuscate* incoming links and optionally shorten outgoing links.

This was created because pay services are expensive, and other options are 
either limited or subject to frequent bitrot.

The modular structure is specifically designed so that it should be easy to 
create a new module for additional services, as it relies on other programs 
to do most of the posting. Therefore, if one posting tool dies, another can be 
found and (relatively) easily swapped in without changing your whole setup.

`agaetr` is an anglicization of ágætr, meaning "famous".

Special thanks to Alvin Alexander's [whose post](https://alvinalexander.com/python/python-script-read-rss-feeds-database) got me on the right track.

## 2. License

This project is licensed under the Apache License. For the full license, see `LICENSE`.

## 3. Prerequisites

These are probably already installed or are easily available from your distro on
linux-like distros:  
 

* [python3](https://www.python.org)  
* [bash](https://www.gnu.org/software/bash/)  
* [wget](https://www.gnu.org/software/wget/)  
* [gawk](http://www.gnu.org/software/gawk/manual/gawk.html)  
* [grep](http://en.wikipedia.org/wiki/Grep)  
* [curl](http://en.wikipedia.org/wiki/CURL)  
* [sed]
* [detox]
* [xmlstarlet]
* [imagemagick]
* lynx
* pandoc
* html-xml-utils

## 4. Installation

The easiest way is to use the flatpak. *Seriously.* There's lots of fiddly bits 
here. If you are using the flatpak, skip to Configuration.


### Manual installation

You will need some variety of posting mechanism and optionally an URL 
shortening mechanism. See [Services Setup](#5-services-setup) for details.

It is strongly recommended to create a virtualenv for this project; the 
installation instructions are written with this in mind.

Ideally, you should create a virtualenv for this project, as there are a number 
of python dependencies.  Instructions on how to do that are beyond the scope of 
this document.  It is assumed that you have created and activated the 
virtualenv henceforth.


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

OR 

`sudo apt install python3-appdirs python3-configargparse python3-requests python3-feedparser python3-bs4`

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


### Shorteners and Archivers

#### YOURLS  

Go to your already functional YOURLS instance.  Get the API key from 
Place the URL of your instance and API key into `agaetr.ini`.  

`yourls_api =`  
`yourls_site =`  

#### ARCHIVE.IS

Install the `archiveis` cli tool from [https://github.com/palewire/archiveis](https://github.com/palewire/archiveis), 
or if you have pipx, by `pipx install archiveis`.

Find the location of the binary by typing `which archiveis`, then place that in 
the ini file. *Placing the binary location turns on archiving all links*.

#### WAYBACK MACHINE

Install the `waybackpy` cli tool from [https://pypi.org/project/waybackpy/](https://pypi.org/project/waybackpy/), 
or if you have pipx, by `pipx install waybackpy`.

Find the location of the binary by typing `which waybackpy`, then place that in 
the ini file. *Placing the binary location turns on archiving all links*.



### Outbound parsers

* Mastodon:
* Shaarli 
* Wallabag                 

Note that each service has its own line in `agaetr.ini`.  Leave blank any 
you are not using; adding additional services should follow the pattern shown.  

### Shaarli (output)

Install and set up the [Shaarli-Client](https://github.com/shaarli/python-shaarli-client). 
Make sure you set up the configuration file for the client properly. Place the 
location of the binary into `agaetr.ini`.

If no configuration is specified in the ini, the default config in `$XDG_DATA_HOME/shaarli/client.ini` will be used. Multiple shaarli configs can be
specified in `agaetr.ini` using this format:

```
[shaarli_config NAME]
shaarli_config = /path/to/config/file
```

At present, the client will loop through ALL configured shaarli instances.

#### Wallabag (output)

Install and set up [Wallabag-cli](https://github.com/Nepochal/wallabag-cli). 
Place the location of the binary into `agaetr.ini`.

Note that shorteners and wallabag don't get along all the time.

#### Mastodon via toot  

Install and set up [toot](https://github.com/ihabunek/toot/).  Place the 
location of the binary into `agaetr.ini`.

#### Bsky via 

#TODO - WRITE THIS UP


#### Matrix via 

#TODO - WRITE THIS UP

#### XMPP via 

#TODO - WRITE THIS UP

#### RSS via 

#TODO - WRITE THIS UP



## 6. Feeds Setup

Information about your feeds goes into `agaetr.ini`.  Each feed is marked by a
header line `[Feed#]` with a different number for each feed. 

If a feed is being preprocessed (see below) or you have the RSS as an 
XML file, you can put the filename directly into `agaetr.ini`, **RELATIVE TO `$XDG_CONFIG_HOME/agaetr`**.  

The options are explained in [Feed Options](#8-feed-options) below.

For example:

```
[Feed1]
url = /feeds/ideatrash_parsed.xml
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

This is being incorporated into the entire flow of the system. However, if you're 
using flatpak, please keep in mind that the binaries called by your "cmd" must be 
accessible either because they're inside the flatpak or because you've given 
the flatpak permissions (e.g. through flatseal or the like)


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

*Note*: Images are marked as sensitive if the content warning is triggered.

```
Sensitive = no
ContentWarning = no
GlobalCW = RSS-fed
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
url = /feeds/ideatrash_parsed.xml
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

# If a path, it must be relative to $XDG_DATA_HOME/agaetr and begin with a slash
# $XDG_DATA_HOME *is* different if you're using Flatpak!
# note the source and command. 
[Feed4]
src = https://ideatrash.net/feed
cmd = sed 's/<div class="more-link-wrapper">.*\]\]><\/description>/\]\]\><\/description>/g'
url = /relative/path/to/xml/filename.xml

```

## 9. Advanced Content Warning

If you need ideas for what tags/terms make good content warnings, the file 
`cwlist.txt` is included for your convenience. Because of how it matches, a 
filter of "abuse" should catch "child abuse" and "sexual abuse", etc. However, 
it matches whole words, so "war" should *not* catch "bloatware" or "warframe".

The advanced content warning system is configured in the `agaetr.ini` as 
well, following a similar format to the feeds:

```
[CW9]
keyword = social-media
matches = facebook twitter mastodon social-media online
```

The "keyword" is what is outputted as the content warning, the space-separated 
line after matches is what strings will trigger that keyword as a content 
warning.  This will work on *all* feeds where `ContentWarning = yes` is 
configured. 

### The keyword should **NOT** be a potentially sensitive word itself.

## 10. Usage

### IMPORTANT NOTE ABOUT CRON

**If you run `agaetr` as a cron job, ensure that the cron job is 
run as the user (and with the environment) you used to set up the 
online services.**  



## 11. Other files

There are other files in this repository:

* `muna.sh` - Used by `agaetr` to remove redirections and shortening.  Exactly the same as [muna](https://github.com/uriel1998/muna).  

## 12. TODO

### Roadmap:

* 1.0 - Full on installation script including venv
* 1.0 - Per feed prefix string (e.g. "Blogging: $Title")
* 1.0 - urldecode strings in titles and descriptions

### Someday/Maybe:



