//
//  IRCSessionDelegate.swift
//  Kathy
//
//  Created by Michael Bujol on 6/21/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import CocoaAsyncSocket.GCDAsyncSocket

extension IRCSession: GCDAsyncSocketDelegate {

    func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("didConnectToHost")
        authenticate()
        DispatchQueue.main.async {
            self.delegate.didReceiveBroadcast("Connected to \(host):\(port)\n")
        }
    }

    func socketDidSecure(_ sock: GCDAsyncSocket!) {
        print("socketDidSecure")
        DispatchQueue.main.async {
            self.delegate.didReceiveBroadcast("Connection secured\n\n")
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socketDidDisconnect")
        DispatchQueue.main.async {
            self.delegate.didReceiveBroadcast(err.localizedDescription + "\n")
        }
    }

    func socket(_ sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("didWriteData")
    }

    func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        print("didReadData")
        readSocket()

        let message = IRCMessage(data: data)
        message.log()
        appendMessageToChannel(consoleChannelName, message: message.raw)

        switch message.command {
        case "PING":
            sendIRCMessage(IRCMessage(command: "PONG", params: message.params))
        case "NICK":
            if let nick = message.prefix?.nick, let newNick = message.params?.replacingOccurrences(of: ":", with: "") {
                currentNick = currentNick == nick ? newNick : currentNick
                (channels.arrangedObjects as? Array<Channel>)?.filter { $0.users.contains(User(nick)) }.forEach { channel in
                    appendMessageToChannel(channel.name, message: "\(nick) is now known as \(newNick)\n")
                    DispatchQueue.main.async {
                        if let user = channel.users.remove(User(nick)) {
                            user.name = newNick
                            channel.users.insert(user)
                            self.channels.rearrangeObjects()
                        }
                    }
                }
            }
        case "PRIVMSG":
            if let nick = message.prefix?.nick, let matches = "(\\S+) :?(.*)".captures(message.params), let text = matches.last, var channel = matches.first {
                if channel == currentNick {
                    channel = nick

                    let notification = NSUserNotification()
                    notification.title = "Message from \(nick)"
                    notification.informativeText = text
                    NSUserNotificationCenter.default.deliver(notification)
                }
                appendMessageToChannel(channel, message: "\(nick): \(text)\n")
            }
        case "JOIN":
            if let channelName = message.params, let nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == currentNick ? "You have" : "\(nick) has") + " joined the channel\n")
                DispatchQueue.main.async {
                    self.getChannel(channelName)?.users.insert(User(nick))
                    self.channels.rearrangeObjects()
                }
            }
        case "PART":
            if let channelName = message.params, let nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == currentNick ? "You have" : "\(nick) has") + " left the channel\n")
                DispatchQueue.main.async {
                    self.getChannel(channelName)?.users.remove(User(nick))
                    self.channels.rearrangeObjects()
                }
            }
        case "353": // part of /NAMES list
            if let matches = "\\S+ [@=*] (\\S+) :?(.*) ?".captures(message.params), let channelName = matches.first, let nicks = matches.last?.split(" ") {
                DispatchQueue.main.async {
                    self.getChannel(channelName)?.users.formUnion(nicks.map { User($0) })
                }
            }
        case "366": // end of /NAMES list
            if let matches = "\\S+ (\\S+) .*".captures(message.params), let channelName = matches.first {
                if let currentChannel = channels.selectedObjects.first as? Channel {
                    if currentChannel.name == channelName {
                        DispatchQueue.main.async {
                            self.channels.rearrangeObjects()
                        }
                    }
                }
            }
        case "TOPIC":
            if let matches = "(\\S+) :?(.*)".captures(message.params), let channel = matches.first, let topic = matches.last {
                appendMessageToChannel(channel, message: "Topic changed: \(topic)\n")
            }
        case "332": // topic response
            if let matches = "\\S+ (\\S+) :?(.*) ?".captures(message.params), let channel = matches.first, let topic = matches.last {
                appendMessageToChannel(channel, message: "Topic: \(topic)\n")
            }
        default:
            break
        }
    }

}
