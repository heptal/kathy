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
        let rect = CGRect.zero
        let style: NSWindowStyleMask = [.titled, .resizable, .miniaturizable, .closable] //NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
        window = NSWindow(contentRect: rect, styleMask: style, backing: .buffered, defer: true)
        windowFrameAutosaveName = windowNibName
    }

    override func windowDidLoad() {
        contentViewController = ChatViewController()
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(contentViewController?.view.subviewWithIdentifier("inputView"))
    }

}
