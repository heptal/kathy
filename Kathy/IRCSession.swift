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

    func didReceiveBroadcast(_ message: String)
    func didReceiveMessage(_ message: String)
    func didReceiveUnreadMessageOnChannel(_ channel: String)
    func didReceiveError(_ error: NSError)

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

        let delegateQueue = DispatchQueue(label: "com.heptal.Kathy.tcpQueue", attributes: [])
        socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
//        socket.IPv4PreferredOverIPv6 = false

        currentNick =  UserDefaults.standard.string(forKey: "nick")

        channels.addObject(Channel(name: consoleChannelName))
    }

    func readSocket() {
        socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: readTimeout, tag: tag)
    }

    func connectToHost(_ host: String, port: UInt16) {
        do {
            try socket.connect(toHost: host, onPort: port)
            if port == 6697 {
                socket.startTLS([kCFStreamSSLPeerName as String: host as NSObject])
            }
            readSocket()
        } catch let error as NSError {
            delegate.didReceiveError(error)
        }

    }

    func authenticate() {
        let userDefaults = UserDefaults.standard
        if let nick = userDefaults.string(forKey: "nick") {
            let user = userDefaults.string(forKey: "user") ?? nick
            let realName = userDefaults.string(forKey: "realName") ?? nick
            let invisible = userDefaults.bool(forKey: "invisible") ? "8" : "0"
            if let pass = userDefaults.string(forKey: "pass") {
                sendIRCMessage(IRCMessage(command: "PASS", params: pass))
            }
            sendIRCMessage(IRCMessage(command: "NICK", params: nick))
            sendIRCMessage(IRCMessage(command: "USER", params: "\(user) \(invisible) * :\(realName)"))
        } else {
            sendIRCMessage(IRCMessage(command: "QUIT", params: nil))
        }
    }

    func sendIRCMessage(_ message: IRCMessage) {
        socket.write(message.data as Data!, withTimeout: writeTimeout, tag: tag)
    }

    func command(_ cmd: String) {
        if cmd.hasPrefix("/server") {
            if let matches = " ([^: ]+)[: ]?(.*)?".captures(cmd), let server = matches.first {
                connectToHost(server, port: UInt16(matches.last!) ?? 6697)
            }

            return
        }

        if cmd.hasPrefix("/msg") {
            if let matches = " (\\S+) (.*)".captures(cmd), let nick = matches.first, let message = matches.last {
                command("/PRIVMSG \(nick) :\(message)")
            }

            return
        }

        if let matches = "/(\\S*) ?(.*)".captures(cmd), let command = matches.first, let params = matches.last {
            sendIRCMessage(IRCMessage(command: command, params: params))
        }
    }

    func getChannel(_ channelName: String) -> Channel? {
        return (channels.arrangedObjects as? Array<Channel>)?.filter { channelName == $0.name }.first
    }

    func setupChannel(_ channelName: String) -> Channel? {
        if getChannel(channelName) == nil {
            let channel = Channel(name: channelName)
            if Thread.isMainThread {
                channels.addObject(channel)
            } else {
                DispatchQueue.main.sync {
                    self.channels.addObject(channel)
                }
            }
        }
        return getChannel(channelName)
    }

    func appendMessageToChannel(_ channelName: String, message: String) {
        if let channel = setupChannel(channelName) {
            channel.log.append(message)
            if let currentChannel = channels.selectedObjects.first as? Channel {
                if channel.name == currentChannel.name {
                    DispatchQueue.main.async {
                        self.delegate.didReceiveMessage(message)
                    }
                } else if channel.name != consoleChannelName {
                    DispatchQueue.main.async {
                        self.delegate.didReceiveUnreadMessageOnChannel(channelName)
                    }
                }
            }
        }
    }

}
