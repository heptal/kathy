//
//  PreferencesWindow.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    static let singleton = PreferencesWindowController()

    override var windowNibName: String? { return "PreferencesWindow" }

    override func loadWindow() {
        let rect = CGRectZero
        let style = NSTitledWindowMask | NSClosableWindowMask
        window = NSWindow(contentRect: rect, styleMask: style, backing: .Buffered, defer: true)
        windowFrameAutosaveName = windowNibName
        window?.title = "Preferences"
    }

    override func windowDidLoad() {
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        contentViewController = PreferencesViewController()
    }

}

class PreferencesViewController: NSViewController {

    override func loadView() {
        let size = CGSize(width: 300, height: 250)
        view = PreferencesView(frame: CGRect(origin: CGPointZero, size: size))
    }

}

class PreferencesView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let userDefaults = NSUserDefaults.standardUserDefaults()

        let stackView = NSStackView(frame: frameRect)
        stackView.orientation = .Vertical
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        addSubview(stackView)

        ["nick", "user", "pass", "realName", "defaultHost"].forEach { (defaultsKey) in
            let textField = defaultsKey == "pass" ? NSSecureTextField() : NSTextField()
            textField.enabled = true
            textField.editable = true
            textField.bind("value", toObject: userDefaults, withKeyPath: defaultsKey, options: nil)
            stackView.addView(NSStackView(views: [leadingLabel("\(defaultsKey.capitalizedString):"), textField]), inGravity: .Top)
        }

        let buttonStackView = NSStackView(views: [leadingLabel("Other:")])
        ["invisible", "autoConnect"].forEach { (defaultsKey) in
            let button = NSButton()
            button.setButtonType(.SwitchButton)
            button.attributedTitle = makeLabel(defaultsKey.capitalizedString, alignment: .Left).attributedStringValue
            button.bind("value", toObject: userDefaults, withKeyPath: defaultsKey, options: nil)
            buttonStackView.addView(button, inGravity: .Top)
        }

        stackView.addView(buttonStackView, inGravity: .Top)
        stackView.views.forEach { (view) in
            NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: stackView, attribute: .Left, multiplier: 1.0, constant: 20).active = true
            NSLayoutConstraint(item: view.subviews[0], attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 80).active = true
            NSLayoutConstraint(item: view.subviews[1], attribute: .Left, relatedBy: .Equal, toItem: view.subviews[0], attribute: .Right, multiplier: 1.0, constant: 10).active = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeLabel(text: String, alignment: NSTextAlignment) -> NSTextField {
        let textField = NSTextField()
        textField.bezeled = false
        textField.drawsBackground = false
        textField.editable = false
        textField.selectable = false
        textField.alignment = alignment
        textField.stringValue = text

        return textField
    }

    private func leadingLabel(text: String) -> NSTextField {
        return makeLabel(text, alignment: .Right)
    }

}
