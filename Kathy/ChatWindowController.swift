//
//  ChatWindowController.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

class ChatWindowController: NSWindowController {

    static let singleton = ChatWindowController()

    override var windowNibName: String? { return "ChatWindow" }

    override func loadWindow() {
        let rect = CGRectZero
        let style = NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
        window = NSWindow(contentRect: rect, styleMask: style, backing: .Buffered, defer: true)
        windowFrameAutosaveName = windowNibName
    }

    override func windowDidLoad() {
        contentViewController = ChatViewController()
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(contentViewController?.view.subviewWithIdentifier("inputView"))
    }

}
