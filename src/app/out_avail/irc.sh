https://serverfault.com/a/259877

 12

IRC is a simple text and line oriented protocol, so it can be done with the basic linux tools. So, without installing ii:

echo -e 'USER bot guest tolmoon tolsun\nNICK bot\nJOIN #channel\nPRIVMSG #channel :Ahoj lidi!\nQUIT\n' \
| nc irc.freenode.net 6667

In this command, nc does the network connection, and you send a login info, nick, join a channel named "#channel" amd send a message "Ahoj lidi!" to that channel. And quit the server.
Share
Improve this answer
Follow
edited Jul 17, 2018 at 21:08
answered Apr 14, 2011 at 22:18
Ondra Žižka's user avatar
Ondra Žižka
43422 gold badges55 silver badges1414 bronze badges

    add \nQUIT at the end of the list of commands to quit right after sending the one message – 
    Walter Heck
    Dec 23, 2011 at 10:10

