# Kathy

## What is this?

This is an IRC client written in Swift.

## Why?

All the ones out there have one annoyance or another, and for fun.

## Features? 

 * TLS
 * IPv6
 * Auto-login
 * Auto-parsing/clickifying URLs
 * Auto-embedding images
 * User list
 * Channel list
 * Channel topics
 * Up/down arrows for history
 * Tab-completion of nicks
 * Private message notifications
 * Not using interface builder

## How do I build?

Install [carthage](https://github.com/Carthage/Carthage) and run `carthage update` to pull in the [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) dependency. Then build and run. Hopefully it will work.

## What next?

 * Timestamps
 * Message consistency
 * Polish notifications
 * Multiple simultaneous servers
 * Make preferences better
 * Streamline IRC command parsing/construction
 * Themes?
 * File transfers?
 * Other protocols? (slack, irccloud)

## Pics?

![](https://i.imgur.com/H6ZPaPX.png)
![](https://i.imgur.com/ajIPdg2.png)
![](https://i.imgur.com/ED3UXq5.png)
![](https://i.imgur.com/cN8SH5g.gif)

## References
 * RFC 1459: https://tools.ietf.org/html/rfc1459
 * RFC 2812: https://tools.ietf.org/html/rfc2812
 * IRC numeric responses: https://www.alien.net.au/irc/irc2numerics.html
 * IRC user modes: https://www.alien.net.au/irc/usermodes.html
