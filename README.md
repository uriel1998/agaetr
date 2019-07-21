rss-to-toot
==================================

To take a list of RSS feeds and to send them to Mastodon, Twitter, Facebook,
and Google Pluse with images, content warnings, and sensitive image links 
when those are available. 

Intended for *single user* use, as personal logins, cookies, and API keys
are required.

Currently works well with feeds from [dlvr.it](https://dlvrit.com/) 
and [shaarli](https://github.com/shaarli/Shaarli) instances. Will 
probably work fine with other well-formed RSS/Atom feeds. *Probably.*

* TODO - to make twitter thing not have API keys in open
* TODO - check global cw
* TODO - add tags from feeds instead of just having them be CW
* TODO - Actually get the FB and G+ posting working automatically
	
# Requirements

* python3
* [toot](https://github.com/ihabunek/toot/)
* [twython](https://github.com/ryanmcgrath/twython)
* [twython-tools](https://github.com/adversary-org/twython-tools) - **IMPORTANT- SEE BELOW**

AND (these are probably already installed or easily available from your package manager/distro)

* [uuidgen](https://www.systutorials.com/docs/linux/man/1-uuidgen/)

# Installation

Install `toot` and `twython` and `wget`
configparser
feedparser
json
bs4
pprint

 via pip3. Use of a virtual enviroment is encouraged for `toot`, at least, but is not required.

## Twython-tools (sort of)

In this archive are two files - `tweet.py` and `tweet.patch` - that require a 
little explanation. I did not need the full functionality of twython-tools, 
and in fact, had a bit of a problem getting the gpg encoding of my app keys 
to work. Further, the functionality I *did* want, that is posting an 
image to Twitter, was always *interactive* when I wanted to enter the 
file on the command line. 

So I (thank you Apache2 license) ripped out the authentication portions and 
hardcoded them, ripped out all the interactive bits, and remade the Twython-tools 
program `tweet-full.py` into `tweet.py`. 

   1.) First of all you have to copy the checkmailrc to ~/.checkmailrc and edit it. Don´t forget to change its
       permissions to 600.

If you wish to see the difference, `tweet.patch` is included for you to verify 
my changes to the code.

You must register a [Twitter application](https://apps.twitter.com) and get 
**user** API codes and type them manually into `tweet.py`.

Usage is `tweet.py --message "Thing to tweet" --file /path/to/file/to/tweet`.

* Posting to Facebook, Google Plus, etc

## IMPORTANT NOTE: 
These do not work great (if at all) yet; you might want to put `FALSE`
in the appropriate sections of the configuration

Due to crappy API restrictions, there isn't a real programmatic way to 
post to these services. However, this is *linux* so, dammit, there is. 
We are going to get around this by the use of `elinks` and the `pexpect` 
python library.

Prior to use, you will need to use elinks and to log in to Facebook 
(use [the mobile site](http://m.facebook.com) ) and to [the main Google page](http://www.google.com).
By default, elinks saves cookies, so you should be good there. 

## Configuration Files

This configuration file is expected to be in `$HOME/.config/rss_social` . 

* `rss_social.rc`

Each line has a single value, without any key. The order is important. Sane 
defaults are in the example file.

* The location of the executable for `toot`
* The location of the executable for `tweet.py` 
* The location of `elinks` (for posting to FB, see below)
* The location of `elinks` (for posting to G+, see below)
* The location of the list of feeds 
* The location for the cache of urls 
* How many articles to send per run
* The location of the URL encoder. One is included for convenience


If you do not wish to post to any service, put a FALSE on the appropriate
line in the configuration file.

* `rss_social_feeds.rc`

This file is simply parsed from the top to the bottom. Only three line beginnings
matter here:

* @CON=Content Warning Text
* @SEN
* @FEED=http://link.to.feed

The first two are entirely option (and separately toggleable, as seen in the 
example).  If @SEN exists, all images processed from that feed will have the
"sensitive" tag on Mastodon. If @CON exists, everything after the equals sign 
will be the content warning descriptor for Mastodon. (See the example file). 
Finally, any line starting with @FEED should be an ATOM/RSS feed which will be
processed.

# Usage

* Run `parse3.sh` on a semi-regular basis (e.g. a cron job)
* Run `send.sh` on a semi-regular basis (e.g. a cron job)
* Profit.

Items are sent on a first _published_ first out, so slapping as many feeds
into this as you like will still result in the first published articles 
being shared first.

# Credits and where a lot of this started

[https://www.linuxjournal.com/content/parsing-rss-news-feed-bash-script]  
[https://linux-tips.com/t/expand-shortened-urls-with-gnu-wget/376]  
[https://www.hyperborea.org/journal/2017/12/mastodon-ifttt/]  
[https://github.com/poga/rss2mastodon]  
[https://github.com/blind-coder/rsstootalizer]  
[https://twitrss.me/]  
[https://gist.github.com/cdown/1163649]
