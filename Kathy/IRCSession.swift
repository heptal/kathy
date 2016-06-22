//
//  IRCSession.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa
import CocoaAsyncSocket.GCDAsyncSocket

protocol IRCDelegate: class {

    func didReceiveBroadcast(message: String)
    func didReceiveMessage(message: String)
    func didReceiveUnreadMessageOnChannel(channel: String)
    func didReceiveError(error: NSError)

}

class IRCSession: NSObject {

    var socket: GCDAsyncSocket!
    let readTimeout = -1.0
    let writeTimeout = 30.0
    let tag = -1

    var currentNick: String!
    let channels = NSArrayController()
    let consoleChannelName = "Server Console"
    unowned let delegate: IRCDelegate

    init(delegate: IRCDelegate) {
        self.delegate = delegate
        super.init()

        let delegateQueue = dispatch_queue_create("com.heptal.Kathy.tcpQueue", nil)
        socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        socket.IPv4PreferredOverIPv6 = false

        currentNick =  NSUserDefaults.standardUserDefaults().stringForKey("nick")

        channels.addObject(Channel(name: consoleChannelName))
    }

    func readSocket() {
        socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: readTimeout, tag: tag)
    }

    func connectToHost(host: String, port: UInt16) {
        do {
            try socket.connectToHost(host, onPort: port)
            if port == 6697 {
                socket.startTLS([kCFStreamSSLPeerName: host])
            }
            readSocket()
        } catch let error as NSError {
            delegate.didReceiveError(error)
        }

    }

    func authenticate() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let nick = userDefaults.stringForKey("nick") {
            let user = userDefaults.stringForKey("user") ?? nick
            let realName = userDefaults.stringForKey("realName") ?? nick
            let invisible = userDefaults.boolForKey("invisible") ? "8" : "0"
            if let pass = userDefaults.stringForKey("pass") {
                sendIRCMessage(IRCMessage(command: "PASS", params: pass))
            }
            sendIRCMessage(IRCMessage(command: "NICK", params: nick))
            sendIRCMessage(IRCMessage(command: "USER", params: "\(user) \(invisible) * :\(realName)"))
        } else {
            sendIRCMessage(IRCMessage(command: "QUIT", params: nil))
        }
    }

    func sendIRCMessage(message: IRCMessage) {
        socket.writeData(message.data, withTimeout: writeTimeout, tag: tag)
    }

    func command(cmd: String) {
        if cmd.hasPrefix("/server") {
            if let matches = " ([^: ]+)[: ]?(.*)?".captures(cmd), server = matches.first {
                connectToHost(server, port: UInt16(matches.last!) ?? 6697)
            }

            return
        }

        if cmd.hasPrefix("/msg") {
            if let matches = " (\\S+) (.*)".captures(cmd), nick = matches.first, message = matches.last {
                command("/PRIVMSG \(nick) :\(message)")
            }

            return
        }

        if let matches = "/(\\S*) ?(.*)".captures(cmd), command = matches.first, params = matches.last {
            sendIRCMessage(IRCMessage(command: command, params: params))
        }
    }

    func getChannel(channelName: String) -> Channel? {
        return (channels.arrangedObjects as? Array<Channel>)?.filter { channelName == $0.name }.first
    }

    func setupChannel(channelName: String) -> Channel? {
        if getChannel(channelName) == nil {
            let channel = Channel(name: channelName)
            if NSThread.isMainThread() {
                channels.addObject(channel)
            } else {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.channels.addObject(channel)
                }
            }
        }
        return getChannel(channelName)
    }

    func appendMessageToChannel(channelName: String, message: String) {
        if let channel = setupChannel(channelName) {
            channel.log.append(message)
            if let currentChannel = channels.selectedObjects.first as? Channel {
                if channel.name == currentChannel.name {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.didReceiveMessage(message)
                    }
                } else if channel.name != consoleChannelName {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.didReceiveUnreadMessageOnChannel(channelName)
                    }
                }
            }
        }
    }

}
