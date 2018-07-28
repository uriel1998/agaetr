#!/usr/bin/env python

'''This demonstrates an FTP "bookmark". This connects to an ftp site; does a
few ftp stuff; and then gives the user interactive control over the session. In
this case the "bookmark" is to a directory on the OpenBSD ftp server. It puts
you in the i386 packages directory. You can easily modify this for other sites.

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

# Note that, for Python 3 compatibility reasons, we are using spawnu and
# importing unicode_literals (above). spawnu accepts Unicode input and
# unicode_literals makes all string literals in this script Unicode by default.
child = pexpect.spawnu('elinks -auto-submit https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fideatrash.net')

print ('waiting for python.org to load')
child.expect ('Warning')
time.sleep(0.1)
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

