//
//  ChatViewController.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

class ChatViewController: NSViewController {

    override func loadView() {
        let size = CGSize(width: 1024, height: 768)
        view = ChatView(frame: CGRect(origin: CGPoint.zero, size: size))
    }

}

class ChatView: NSView {

    var session: IRCSession!
    var textView: NSTextView!
    var channelTableView: NSTableView!
    var userTableView: NSTableView!
    var historyIndex: Int!

    let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let userDefaults = UserDefaults.standard

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // Build the interface
        let mainSplitView = NSSplitView(frame: frameRect)
        mainSplitView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        mainSplitView.translatesAutoresizingMaskIntoConstraints = true
        mainSplitView.autoresizesSubviews = true
        mainSplitView.isVertical = true
        mainSplitView.dividerStyle = .thin
        addSubview(mainSplitView)

        let stackView = NSStackView()
        stackView.orientation = .vertical
        mainSplitView.addSubview(stackView)

        let chatTextView = ChatTextView()
        stackView.addView(chatTextView, in: .top)

        let inputView = NSTextField()
        inputView.identifier = "inputView"
        inputView.delegate = self
        stackView.addView(inputView, in: .top)

        let sideSplitView = NSSplitView(frame: frameRect)
        sideSplitView.isVertical = false
        mainSplitView.addSubview(sideSplitView)

        let channelView = ChannelView()
        sideSplitView.addSubview(channelView)

        let userView = UserView()
        sideSplitView.addSubview(userView)

        NSLayoutConstraint.soloConstraint(sideSplitView, attr: .width, relation: .lessThanOrEqual, amount: 200).isActive = true
        NSLayoutConstraint.soloConstraint(sideSplitView, attr: .width, relation: .greaterThanOrEqual, amount: 100).isActive = true
        NSLayoutConstraint.soloConstraint(channelView, attr: .height, relation: .greaterThanOrEqual, amount: 100).isActive = true

        // Start it all up
        resetHistoryIndex()
        session = IRCSession(delegate: self)
        textView = chatTextView.subviewWithIdentifier("chatView") as? NSTextView
        channelTableView = channelView.subviewWithIdentifier("channelTableView") as? NSTableView
        userTableView = userView.subviewWithIdentifier("userTableView") as? NSTableView

        // Bind table views
        let users = NSArrayController()
        users.bind("contentSet", to: session.channels, withKeyPath: "selection.users", options: nil)
        users.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        channelTableView.bind("content", to: session.channels, withKeyPath: "arrangedObjects.name", options: nil)
        channelTableView.bind("selectionIndexes", to: session.channels, withKeyPath: "selectionIndexes", options: nil)
        userTableView.bind("content", to: users, withKeyPath: "arrangedObjects.description", options: nil)
        userTableView.doubleAction = #selector(didDoubleClickUser)
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectChannel), name: NSNotification.Name.NSTableViewSelectionDidChange, object: nil)

        // Connect
        if let host = userDefaults.string(forKey: "defaultHost") {
            if userDefaults.bool(forKey: "autoConnect") {
                session?.command("/server \(host)")
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didDoubleClickUser(_ tableView: NSTableView) {
        if let userRow = tableView.view(atColumn: 0, row: tableView.selectedRow, makeIfNecessary: false) as? NSTextField {
            if let userChannel = session.setupChannel(User(userRow.stringValue).name) {
                session.channels.setSelectedObjects([userChannel])
            }
        }
    }

    func didSelectChannel(_ notification: Notification?) {
        if let tableView = notification?.object as? NSTableView {
            if tableView == channelTableView {
                if let channelRow = tableView.view(atColumn: 0, row: tableView.selectedRow, makeIfNecessary: false) as? NSTextField {
                    channelRow.textColor = NSColor.black
                }
            }
        }

        if let channel = session.channels.selectedObjects.first as? Channel {
            window?.title = channel.name
            textView.layoutManager?.replaceTextStorage(NSTextStorage(attributedString: formatMessage(channel.log.joined(separator: ""))))
            textView.scrollToEndOfDocument(nil)
        }
    }

    func appendMessageToActiveChannel(_ message: String) {
        textView.textStorage?.append(formatMessage(message))
        scrollIfNeeded()
    }

    func scrollIfNeeded() { // autoscroll if near bottom - may be a better way to do this?
        if let scrollRect = textView.enclosingScrollView?.contentView.documentVisibleRect {
            let viewRect = textView.preparedContentRect
            if ((viewRect.size.height - scrollRect.size.height) - scrollRect.origin.y) <= 30 {
                textView.scrollToEndOfDocument(nil)
            }
        }
    }

    func formatMessage(_ message: String) -> NSMutableAttributedString {
        let color = NSColor.black
        let font = NSFont(name: "Menlo", size: 12)!
        let textAttributes = [NSForegroundColorAttributeName: color, NSFontAttributeName: font]
        let attributedText = NSMutableAttributedString(string: message, attributes: textAttributes)

        detector.matches(in: message, options: [], range: NSMakeRange(0, (message as NSString).length)).forEach { (urlMatch) in
            if let url = urlMatch.url {
                let ext = url.pathExtension
                attributedText.addAttribute(NSLinkAttributeName, value: url, range: urlMatch.range)

                if "jpgjpegpnggif".contains(ext) {
                    let attachmentCell = NSTextAttachmentCell(imageCell: NSImage(contentsOf: url))
                    let attachment = NSTextAttachment()
                    attachment.attachmentCell = attachmentCell
                    attributedText.append(NSAttributedString(string: "\n"))
                    attributedText.append(NSAttributedString(attachment: attachment))
                    attributedText.append(NSAttributedString(string: "\n\n"))
                }
            }
        }

        return attributedText
    }

}

extension ChatView: IRCDelegate {

    func didReceiveBroadcast(_ message: String) {
        (session.channels.arrangedObjects as? Array<Channel>)?.forEach { $0.log.append(message) }
        appendMessageToActiveChannel(message)
    }

    func didReceiveMessage(_ message: String) {
        appendMessageToActiveChannel(message)
    }

    func didReceiveUnreadMessageOnChannel(_ channel: String) {
        channelTableView.enumerateAvailableRowViews { (rowView, row) in
            if let channelRow = rowView.view(atColumn: 0) as? NSTextField {
                if channelRow.stringValue == channel {
                    channelRow.textColor = NSColor.orange
                }
            }
        }
    }

    func didReceiveError(_ error: NSError) {
        NSAlert(error: error).runModal()
    }

}
