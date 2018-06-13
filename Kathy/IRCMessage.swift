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

    var data: Data! {
        return raw.data(using: String.Encoding.utf8)
    }

    init(data: Data) {
        raw = String(data: data, encoding: String.Encoding.utf8)
        var message = raw.replacingOccurrences(of: "\r\n", with: "", options: [.anchored, .backwards], range: nil)
        var messagePrefix: IRCMessagePrefix?
        if let prefixEnd = message.characters.index(of: " ") {
            if message.hasPrefix(":") {
                messagePrefix = IRCMessagePrefix(prefix: message.substring(to: prefixEnd))
                message = message.substring(from: message.index(after: prefixEnd))
            }
        }

        if let index = message.characters.index(of: " ") {
            command = message.substring(to: index)
            params = message.substring(from: message.index(after: index))
        } else {
            command = message
            params = nil
        }

        prefix = command != "MODE" ? messagePrefix : nil
    }

    init(command cmd: String, params parameters: String?) {
        command = cmd.uppercased()
        params = parameters
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
    let host: URL!
    let raw: String!

    init?(prefix: String) {
        guard var index = prefix.characters.index(of: ":") else {
            return nil
        }

        if let nickEnd = prefix.characters.index(of: "!"), let userEnd = prefix.characters.index(of: "@") {
            nick = prefix[prefix.index(after: index)..<nickEnd]
            user = prefix[prefix.index(after: nickEnd)..<userEnd]
            index = userEnd
        } else {
            nick = nil
            user = nil
        }

        host = URL(string: prefix.substring(from: prefix.index(after: index)))
        raw = prefix
    }

    var description: String {
        return "\(raw)\nhost:\(host)\nnick:\(nick ?? nil)\nuser:\(user ?? nil)"
    }
}

extension IRCMessage {

    func log() {
        let fm = FileManager.default

        if let supportDir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let appSupportDir = supportDir.appendingPathComponent("/Kathy")
//            if let appSupportDirPath = appSupportDir.path {
                if !fm.fileExists(atPath: appSupportDir.path) {
                    let _ = try? fm.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
                }

                let logFile = appSupportDir.path + "/log.txt"

                if !fm.fileExists(atPath: logFile) {
                    fm.createFile(atPath: logFile, contents: nil, attributes: nil)
                }

                if let fh = FileHandle(forUpdatingAtPath: logFile) {
                    fh.seekToEndOfFile()
                    fh.write(self.data)
                    fh.closeFile()
                }
//            }
        }
    }

}
