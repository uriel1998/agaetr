# agaetr

A modular system to take a list of RSS feeds, process them, and send them to social media with images, content warnings, and sensitive image flags when available. Also includes an example of a daily post creator (such as for Postie and WordPress), bookmarking utility for newsboat, and a GUI poster, `hooty`.

## What is agaetr?

`agaetr` is a modular system made up of several small programs designed to take input (particularly RSS feeds) and then share them to various social media outputs. The system is designed for single user use, as API keys are required. Setting up multiple posters is a significant initial effort, but the idea is that once you've done that once, you can use it for `agaetr`, `mutt`, GUI tools, a bookmarker for `newsboat`, etc., without further configuration.

`agaetr` is an anglicization of ágætr, meaning "famous".

## Key Features

- **RSS Feed Processing**: Automatically processes RSS feeds from various sources
- **Multi-platform Posting**: Send to multiple social media platforms simultaneously
- **Content Warnings**: Advanced content warning system with keyword matching
- **Image Handling**: Automatic image detection, alt-text generation, and sensitive content flagging
- **URL Processing**: Link deobfuscation and optional shortening
- **Preprocessing**: Custom preprocessing scripts for non-standard RSS feeds
- **Modular Architecture**: Easy to add new services and customize behavior
- **Archival Support**: Integration with Wayback Machine for link preservation

***
## Architecture Philosophy

This was created because pay services are expensive, and other options are either limited or subject to frequent bitrot. The modular structure is specifically designed so that it should be easy to create a new module for additional services, as it relies on other programs to do most of the posting. Therefore, if one posting tool dies, another can be found and relatively easily swapped in without changing your whole setup.

One of the reasons there are multiple different example service wrappers (and that they are written in straightforward BASH scripting) is so that future users (including yourself) can use them as templates or examples for other tools or new services with as little fuss as possible and without requiring extensive knowledge.

Special thanks to Alvin Alexander, [whose post](https://alvinalexander.com/python/python-script-read-rss-feeds-database) got me on the right track.

[Installation and documentation is at the wiki](https://github.com/uriel1998/agaetr/wiki).

## TODO

### Roadmap:
* Cleanup code and ini parsing for standardization.
* Doublecheck RSS feed generation, it's a PITA
* send via beeper to recipient(s)
* linkedin (via crossposter)
* reduce logspam
* record success/failure for each outbound source.
* store data in sqlite perhaps, instead of a straight text file
