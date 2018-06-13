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
        let rect = CGRect.zero
        let style: NSWindowStyleMask = [.titled, .closable]
        window = NSWindow(contentRect: rect, styleMask: style, backing: .buffered, defer: true)
        windowFrameAutosaveName = windowNibName
        window?.title = "Preferences"
    }

    override func windowDidLoad() {
        contentViewController = PreferencesViewController()
        window?.center()
    }

}

class PreferencesViewController: NSViewController {

    override func loadView() {
        let size = CGSize(width: 300, height: 250)
        view = PreferencesView(frame: CGRect(origin: CGPoint.zero, size: size))
    }

}

class PreferencesView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let userDefaults = UserDefaults.standard

        let stackView = NSStackView(frame: frameRect)
        stackView.orientation = .vertical
        stackView.edgeInsets = EdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        addSubview(stackView)

        ["nick", "user", "pass", "realName", "defaultHost"].forEach { (defaultsKey) in
            let textField = defaultsKey == "pass" ? NSSecureTextField() : NSTextField()
            textField.isEnabled = true
            textField.isEditable = true
            textField.bind("value", to: userDefaults, withKeyPath: defaultsKey, options: nil)
            stackView.addView(NSStackView(views: [leadingLabel("\(defaultsKey.capitalized):"), textField]), in: .top)
        }

        let buttonStackView = NSStackView(views: [leadingLabel("Other:")])
        ["invisible", "autoConnect"].forEach { (defaultsKey) in
            let button = NSButton()
            button.setButtonType(.switch)
            button.attributedTitle = makeLabel(defaultsKey.capitalized, alignment: .left).attributedStringValue
            button.bind("value", to: userDefaults, withKeyPath: defaultsKey, options: nil)
            buttonStackView.addView(button, in: .top)
        }

        stackView.addView(buttonStackView, in: .top)
        stackView.views.forEach { (view) in
            NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: stackView, attribute: .left, multiplier: 1.0, constant: 20).isActive = true
            NSLayoutConstraint(item: view.subviews[0], attribute: .right, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 80).isActive = true
            NSLayoutConstraint(item: view.subviews[1], attribute: .left, relatedBy: .equal, toItem: view.subviews[0], attribute: .right, multiplier: 1.0, constant: 10).isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func makeLabel(_ text: String, alignment: NSTextAlignment) -> NSTextField {
        let textField = NSTextField()
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.alignment = alignment
        textField.stringValue = text

        return textField
    }

    fileprivate func leadingLabel(_ text: String) -> NSTextField {
        return makeLabel(text, alignment: .right)
    }

}
