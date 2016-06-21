//
//  IRCSessionDelegate.swift
//  Kathy
//
//  Created by Michael Bujol on 6/21/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import CocoaAsyncSocket.GCDAsyncSocket

extension IRCSession: GCDAsyncSocketDelegate {

    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("didConnectToHost")
        authenticate()
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveBroadcast("Connected to \(host):\(port)\n")
        }
    }

    func socketDidSecure(sock: GCDAsyncSocket!) {
        print("socketDidSecure")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveBroadcast("Connection secured\n\n")
        }
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socketDidDisconnect")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveBroadcast(err.localizedDescription + "\n")
        }
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("didWriteData")
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print("didReadData")
        readSocket()

        let message = IRCMessage(data: data)
        message.log()
        appendMessageToChannel(consoleChannelName, message: message.raw)

        switch message.command {
        case "PING":
            sendIRCMessage(IRCMessage(command: "PONG", params: message.params))
        case "NICK":
            if let nick = message.prefix?.nick, newNick = message.params?.stringByReplacingOccurrencesOfString(":", withString: "") {
                currentNick = currentNick == nick ? newNick : currentNick
                (channels.arrangedObjects as? Array<Channel>)?.filter { $0.users.contains(User(nick)) }.forEach { channel in
                    appendMessageToChannel(channel.name, message: "\(nick) is now known as \(newNick)\n")
                    dispatch_async(dispatch_get_main_queue()) {
                        if let user = channel.users.remove(User(nick)) {
                            user.name = newNick
                            channel.users.insert(user)
                            self.channels.rearrangeObjects()
                        }
                    }
                }
            }
        case "PRIVMSG":
            if let nick = message.prefix?.nick, matches = "(\\S+) :?(.*)".captures(message.params), text = matches.last, var channel = matches.first {
                if channel == currentNick {
                    channel = nick

                    let notification = NSUserNotification()
                    notification.title = "Message from \(nick)"
                    notification.informativeText = text
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
                appendMessageToChannel(channel, message: "\(nick): \(text)\n")
            }
        case "JOIN":
            if let channelName = message.params, nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == currentNick ? "You have" : "\(nick) has") + " joined the channel\n")
                dispatch_async(dispatch_get_main_queue()) {
                    self.getChannel(channelName)?.users.insert(User(nick))
                    self.channels.rearrangeObjects()
                }
            }
        case "PART":
            if let channelName = message.params, nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == currentNick ? "You have" : "\(nick) has") + " left the channel\n")
                dispatch_async(dispatch_get_main_queue()) {
                    self.getChannel(channelName)?.users.remove(User(nick))
                    self.channels.rearrangeObjects()
                }
            }
        case "353": // part of /NAMES list
            if let matches = "\\S+ [@=*] (\\S+) :?(.*) ?".captures(message.params), channelName = matches.first, nicks = matches.last?.split(" ") {
                dispatch_async(dispatch_get_main_queue()) {
                    self.getChannel(channelName)?.users.unionInPlace(nicks.map { User($0) })
                }
            }
        case "366": // end of /NAMES list
            if let matches = "\\S+ (\\S+) .*".captures(message.params), channelName = matches.first {
                if let currentChannel = channels.selectedObjects.first as? Channel {
                    if currentChannel.name == channelName {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.channels.rearrangeObjects()
                        }
                    }
                }
            }
        case "TOPIC":
            if let matches = "(\\S+) :?(.*)".captures(message.params), channel = matches.first, topic = matches.last {
                appendMessageToChannel(channel, message: "Topic changed: \(topic)\n")
            }
        case "332": // topic response
            if let matches = "\\S+ (\\S+) :?(.*) ?".captures(message.params), channel = matches.first, topic = matches.last {
                appendMessageToChannel(channel, message: "Topic: \(topic)\n")
            }
        default:
            break
        }
    }

}
