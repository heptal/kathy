//
//  IRCSession.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import CocoaAsyncSocket.GCDAsyncSocket

protocol IRCDelegate: class {

    func didReceiveIRCMessage(message: IRCMessage)
    func didReceiveStringMessage(message: String)
    func didReceiveError(error: NSError)
}

class IRCSession: NSObject {

    var socket: GCDAsyncSocket!
    let readTimeout = -1.0
    let writeTimeout = 30.0
    let tag = -1
    unowned let delegate: IRCDelegate

    init(delegate: IRCDelegate) {
        self.delegate = delegate
        super.init()

        let delegateQueue = dispatch_queue_create("com.heptal.Kathy.tcpQueue", nil)
        socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        socket.IPv4PreferredOverIPv6 = false
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

    func command(message: String) {
        let commandMessage = message.substringFromIndex(message.startIndex.successor())
        print(commandMessage)

        if commandMessage.hasPrefix("server") {
            if let serverIndex = commandMessage.characters.indexOf(" ") {
                let server = commandMessage.substringFromIndex(serverIndex.successor())
                if let portIndex = server.characters.indexOf(" "), port = UInt16(server.substringFromIndex(portIndex.successor())) {
                    connectToHost(server.substringToIndex(portIndex), port: port)
                } else {
                    connectToHost(server, port: 6697)
                }
            }

            return
        }

        if commandMessage.hasPrefix("msg") {
            let parts = commandMessage.split(" ")
            if parts.count > 2 {
                let nick = parts[1]
                let message = parts.dropFirst(2).joinWithSeparator(" ")
                command("/PRIVMSG \(nick) :\(message)")
            }

            return
        }

        if let paramIndex = commandMessage.characters.indexOf(" ") {
            let command = commandMessage.substringToIndex(paramIndex)
            let params = commandMessage.substringFromIndex(paramIndex.successor())
            sendIRCMessage(IRCMessage(command: command, params: params))
        } else {
            sendIRCMessage(IRCMessage(command: commandMessage, params: nil))
        }
    }

}

extension IRCSession: GCDAsyncSocketDelegate {

    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("didConnectToHost")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveStringMessage("Connected to \(host):\(port)\n")
            self.authenticate()
        }
    }

    func socketDidSecure(sock: GCDAsyncSocket!) {
        print("socketDidSecure")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveStringMessage("Connection secured\n\n")
        }
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socketDidDisconnect")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveStringMessage(err.localizedDescription)
        }
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("didWriteData")
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print("didReadData")
        readSocket()

        let message = IRCMessage(data: data)
        if message.command == "PING" {
            sendIRCMessage(IRCMessage(command: "PONG", params: message.params))
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.didReceiveIRCMessage(message)
        }
    }

}
