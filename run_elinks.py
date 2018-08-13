#!/usr/bin/env python

'''

PEXPECT LICENSE

    This license is approved by the OSI and FSF as GPL-compatible.
        http://opensource.org/licenses/isc-license.txt

    Copyright (c) 2012, Noah Spurrier <noah@noah.org>
    PERMISSION TO USE, COPY, MODIFY, AND/OR DISTRIBUTE THIS SOFTWARE FOR ANY
    PURPOSE WITH OR WITHOUT FEE IS HEREBY GRANTED, PROVIDED THAT THE ABOVE
    COPYRIGHT NOTICE AND THIS PERMISSION NOTICE APPEAR IN ALL COPIES.
    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

'''

from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import argparse
import pexpect
import sys
import time
import datetime

KEY_UP = '\x1b[A'
KEY_DOWN = '\x1b[B'
KEY_RIGHT = '\x1b[C'
KEY_LEFT = '\x1b[D'
KEY_ESCAPE = '\x1b'
KEY_BACKSPACE = '\x7f'
KEY_ENTER = '\x1b[13'

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('-e','--execute', action='store',dest='execute', type=str, nargs='+')
parser.add_argument('-c', '--command', action='store',dest='command', type=str, nargs='+')
parser.add_argument('-u', '--url', action='store', dest='url', type=str)
args = parser.parse_args()

#exe = str(args.execute)
#url = str(args.url)
#command = str(args.command)  
#exe = args.execute
url = args.url
#command = args.command  

print (url)
# Note that, for Python 3 compatibility reasons, we are using spawnu and
# importing unicode_literals (above). spawnu accepts Unicode input and
# unicode_literals makes all string literals in this script Unicode by default.
#child = pexpect.spawnu(exe + ' -' + command + ' ' + url)
child = pexpect.spawnu('./browser.sh' + ' ' + url)
child.logfile = open("/tmp/mylog", "w")
print ('Waiting for it to load...')
#child.expect ('Warning')
time.sleep(1)
child.send("\r")
child.sendline(KEY_ENTER)  # "the requested fragment doesn't exist ... but it did post."
print ('quitting')
child.sendline('q')
child.sendline(KEY_ENTER)


# The rest is not strictly necessary. This just demonstrates a few functions.
# This makes sure the child is dead; although it would be killed when Python exits.
if child.isalive():
    child.sendline('bye') # Try to ask ftp child to exit.
    child.close()
# Print the final state of the child. Normally isalive() should be FALSE.
if child.isalive():
    print('Child did not exit gracefully.')
else:
    print('Child exited gracefully.')

