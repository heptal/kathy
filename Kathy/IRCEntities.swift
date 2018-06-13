//
//  IRCEntities.swift
//  Kathy
//
//  Created by Michael Bujol on 6/19/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

class Channel: NSObject {
    let name: String
    var log: [String] = []
    var users: Set<User> = []

    init(name: String) {
        self.name = name
    }

}

class User: NSObject {
    var name: String = ""
    var mode: String = ""

    init(_ modeName: String) {
        if let matches = "([~&@%+]?)(.*)".captures(modeName), let modePart = matches.first, let namePart = matches.last {
            name = namePart
            mode = modePart
        }
    }

    override var description: String {
        return mode + name
    }

    override var hashValue: Int {
        return name.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        return (object as? User)?.name == name
    }

}
