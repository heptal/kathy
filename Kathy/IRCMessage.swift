//
//  IRCMessage.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Foundation

struct IRCMessage: CustomStringConvertible {
    let prefix: IRCMessagePrefix?
    let command: String
    let params: String?
    let raw: String!

    var data: NSData! {
        return raw.dataUsingEncoding(NSUTF8StringEncoding)
    }

    init(data: NSData) {
        raw = String(data: data, encoding: NSUTF8StringEncoding)
        var message = raw.stringByReplacingOccurrencesOfString("\r\n", withString: "", options: [.AnchoredSearch, .BackwardsSearch], range: nil)

        let prefixEnd = message.characters.indexOf(" ")
        var messagePrefix: IRCMessagePrefix?
        if message.hasPrefix(":") && prefixEnd != nil {
            messagePrefix = IRCMessagePrefix(prefix: message.substringToIndex(prefixEnd!))
            message = message.substringFromIndex(prefixEnd!.successor())
        }

        if let index = message.characters.indexOf(" ") {
            command = message.substringToIndex(index)
            params = message.substringFromIndex(index.successor())
        } else {
            command = message
            params = nil
        }

        prefix = command != "MODE" ? messagePrefix : nil
    }

    init(command: String, params: String?) {
        self.command = command.uppercaseString
        self.params = params
        prefix = nil
        raw = command + (params != nil ? " \(params!)" : "") + "\r\n"
    }

    var description: String {
        return "\(raw)\nprefix:\(prefix ?? nil)\ncommand:\(command)\nparams:\(params ?? nil)"
    }
}

struct IRCMessagePrefix: CustomStringConvertible {
    let nick: String?
    let user: String?
    let host: NSURL!
    let raw: String!

    init?(prefix: String) {
        guard var index = prefix.characters.indexOf(":") else {
            return nil
        }

        if let nickEnd = prefix.characters.indexOf("!"), userEnd = prefix.characters.indexOf("@") {
            nick = prefix.substringWithRange(Range(index.successor()..<nickEnd))
            user = prefix.substringWithRange(Range(nickEnd.successor()..<userEnd))
            index = userEnd
        } else {
            nick = nil
            user = nil
        }

        host = NSURL(string: prefix.substringFromIndex(index.successor()))
        raw = prefix
    }

    var description: String {
        return "\(raw)\nhost:\(host)\nnick:\(nick ?? nil)\nuser:\(user ?? nil)"
    }
}
