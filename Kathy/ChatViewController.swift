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
        view = ChatView(frame: CGRect(origin: CGPointZero, size: size))
    }

}

class ChatView: NSView {

    var session: IRCSession!
    var textView: NSTextView!
    var historyIndex: Int!

    let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
    let userDefaults = NSUserDefaults.standardUserDefaults()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // Build the interface
        let mainSplitView = NSSplitView(frame: frameRect)
        mainSplitView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        mainSplitView.translatesAutoresizingMaskIntoConstraints = true
        mainSplitView.autoresizesSubviews = true
        mainSplitView.vertical = true
        mainSplitView.dividerStyle = .Thin
        addSubview(mainSplitView)

        let stackView = NSStackView()
        stackView.orientation = .Vertical
        mainSplitView.addSubview(stackView)

        let chatTextView = ChatTextView()
        stackView.addView(chatTextView, inGravity: .Top)

        let inputView = NSTextField()
        inputView.identifier = "inputView"
        inputView.delegate = self
        stackView.addView(inputView, inGravity: .Top)

        let sideSplitView = NSSplitView(frame: frameRect)
        sideSplitView.vertical = false
        mainSplitView.addSubview(sideSplitView)

        let channelView = ChannelView()
        sideSplitView.addSubview(channelView)

        let userView = UserView()
        sideSplitView.addSubview(userView)

        NSLayoutConstraint.soloConstraint(sideSplitView, attr: .Width, relation: .LessThanOrEqual, amount: 200).active = true
        NSLayoutConstraint.soloConstraint(sideSplitView, attr: .Width, relation: .GreaterThanOrEqual, amount: 100).active = true
        NSLayoutConstraint.soloConstraint(channelView, attr: .Height, relation: .GreaterThanOrEqual, amount: 100).active = true

        // Start it all up
        resetHistoryIndex()
        textView = chatTextView.subviewWithIdentifier("chatView") as? NSTextView
        session = IRCSession(delegate: self)

        // Bind table views
        let channelTableView = channelView.subviewWithIdentifier("channelView") as? NSTableView
        channelTableView?.bind("content", toObject: session.channels, withKeyPath: "arrangedObjects.name", options: nil)
        channelTableView?.bind("selectionIndexes", toObject: session.channels, withKeyPath: "selectionIndexes", options: nil)
        let users = NSArrayController()
        users.bind("contentSet", toObject: session.channels, withKeyPath: "selection.users", options: nil)
        users.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        let userTableView = userView.subviewWithIdentifier("userView") as? NSTableView
        userTableView?.bind("content", toObject: users, withKeyPath: "arrangedObjects.description", options: nil)
        userTableView?.doubleAction = #selector(didDoubleClickUser)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didSelectChannel), name: NSTableViewSelectionDidChangeNotification, object: nil)

        // Connect
        if let host = userDefaults.stringForKey("defaultHost") {
            if userDefaults.boolForKey("autoConnect") {
                session?.command("/server \(host)")
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didDoubleClickUser(tableView: NSTableView) {
        if let row = tableView.rowViewAtRow(tableView.selectedRow, makeIfNecessary: false)?.viewAtColumn(tableView.clickedColumn) as? NSTextField {
            if let userChannel = session.setupChannel(User(row.stringValue).name) {
                session.channels.setSelectedObjects([userChannel])
            }
        }
    }

    func didSelectChannel(notification: AnyObject?) {
        if let channel = session.channels.selectedObjects.first as? Channel {
            window?.title = channel.name
            textView.layoutManager?.replaceTextStorage(NSTextStorage(attributedString: formatMessage(channel.log.joinWithSeparator(""))))
            textView.scrollToEndOfDocument(nil)

        }
    }

    func appendMessageToActiveChannel(message: String) {
        textView.textStorage?.appendAttributedString(formatMessage(message))
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

    func formatMessage(message: String) -> NSMutableAttributedString {
        let color = NSColor.blackColor()
        let font = NSFont(name: "Menlo", size: 12)!
        let textAttributes = [NSForegroundColorAttributeName: color, NSFontAttributeName: font]
        let attributedText = NSMutableAttributedString(string: message, attributes: textAttributes)

        detector.matchesInString(message, options: [], range: NSMakeRange(0, (message as NSString).length)).forEach { (urlMatch) in
            if let url = urlMatch.URL, ext = url.pathExtension {
                attributedText.addAttribute(NSLinkAttributeName, value: url, range: urlMatch.range)

                if "jpgjpegpnggif".containsString(ext) {
                    let attachmentCell = NSTextAttachmentCell(imageCell: NSImage(contentsOfURL: url))
                    let attachment = NSTextAttachment()
                    attachment.attachmentCell = attachmentCell
                    attributedText.appendAttributedString(NSAttributedString(string: "\n"))
                    attributedText.appendAttributedString(NSAttributedString(attachment: attachment))
                    attributedText.appendAttributedString(NSAttributedString(string: "\n\n"))
                }
            }
        }

        return attributedText
    }

}

extension ChatView: IRCDelegate {

    func didReceiveBroadcast(message: String) {
        (session.channels.arrangedObjects as? Array<Channel>)?.forEach { $0.log.append(message) }
        appendMessageToActiveChannel(message)
    }

    func didReceiveMessage(message: String) {
        appendMessageToActiveChannel(message)
    }

    func didReceiveError(error: NSError) {
        NSAlert(error: error).runModal()
    }

}
