//
//  ChatViewController.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

class Channel: NSObject {
    let name: String
    let contents: NSTextStorage
    var users: Set<String> = []

    init(name: String, contents: NSTextStorage?) {
        self.name = name
        self.contents = contents ?? NSTextStorage()
    }
}

class ChatViewController: NSViewController {

    override func loadView() {
        let size = CGSize(width: 1024, height: 768)
        view = ChatView(frame: CGRect(origin: CGPointZero, size: size))
    }

}

class ChatView: NSView {

    var session: IRCSession?
    var nick: String!
    var console: Channel!
    var textView: NSTextView!
    var historyIndex: Int!
    let channels = NSArrayController()

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

        // Bind table views
        let channelTableView = channelView.subviewWithIdentifier("channelView") as? NSTableView
        channelTableView?.bind("content", toObject: channels, withKeyPath: "arrangedObjects.name", options: nil)
        channelTableView?.bind("selectionIndexes", toObject: channels, withKeyPath: "selectionIndexes", options: nil)

        let users = NSArrayController()
        users.bind("contentSet", toObject: channels, withKeyPath: "selection.users", options: nil)
        users.sortDescriptors = [NSSortDescriptor(key: nil, ascending: true) { ($0 as! String).compare($1 as! String, options: .CaseInsensitiveSearch) }]
        users.automaticallyRearrangesObjects = true
        let userTableView = userView.subviewWithIdentifier("userView") as? NSTableView
        userTableView?.bind("content", toObject: users, withKeyPath: "arrangedObjects", options: nil)

        // Start it all up
        resetHistoryIndex()
        session = IRCSession(delegate: self)
        nick = userDefaults.stringForKey("nick")
        channels.selectsInsertedObjects = true
        console = getChannel("Server Console", contents: "Welcome to Kathy\n\n")
        textView = chatTextView.subviewWithIdentifier("chatView") as? NSTextView
        textView.layoutManager?.replaceTextStorage(console.contents)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didSelectChannel), name: NSTableViewSelectionDidChangeNotification, object: nil)
        if let host = userDefaults.stringForKey("defaultHost") {
            if userDefaults.boolForKey("autoConnect") {
                session?.command("/server \(host)")
            }
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didSelectChannel(notification: AnyObject?) {
        if let channel = channels.selectedObjects.first as? Channel {
            window?.title = channel.name
            textView.layoutManager?.replaceTextStorage(channel.contents)
            textView.scrollToEndOfDocument(nil)
        }
    }

    func getChannel(channelName: String, contents: String?) -> Channel {
        if let channel = (channels.arrangedObjects as? Array<Channel>)?.filter({ (channel) -> Bool in
            channelName == channel.name
        }).first {
            return channel
        } else {
            return setupChannel(channelName, contents: contents)
        }
    }

    func setupChannel(channelName: String, contents: String?) -> Channel {
        let channel = Channel(name: channelName, contents: NSTextStorage(attributedString: formatMessage(contents ?? "")))
        channels.addObject(channel)
        return channel
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
                    attributedText.appendAttributedString(NSAttributedString(string: "\n\n"))
                    attributedText.appendAttributedString(NSAttributedString(attachment: attachment))
                    attributedText.appendAttributedString(NSAttributedString(string: "\n\n"))
                }
            }
        }

        return attributedText
    }

    func appendMessageToChannel(channelName: String, message: String) {
        let channel = getChannel(channelName, contents: nil)
        channel.contents.appendAttributedString(formatMessage(message))
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

}

extension ChatView: IRCDelegate {

    func didReceiveIRCMessage(message: IRCMessage) {
        console.contents.appendAttributedString(formatMessage(message.raw))

        switch message.command {
        case "NICK":
            if let oldNick = message.prefix?.nick, newNick = message.params?.stringByReplacingOccurrencesOfString(":", withString: "") {
                if nick == oldNick {
                    nick = newNick
                }
            }
        case "JOIN":
            if let channel = message.params {
                getChannel(channel, contents: nil)
            }
        case "PRIVMSG":
            if let params = message.params, index = params.characters.indexOf(" "), nick = message.prefix?.nick {
                var channel = params.substringToIndex(index)
                let text = params.substringFromIndex(index.successor().successor()) // Skip space and colon
                if channel == self.nick {
                    channel = nick

                    let notification = NSUserNotification()
                    notification.title = "Message from \(nick)"
                    notification.informativeText = text
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
                appendMessageToChannel(channel, message: "\(message.prefix?.nick ?? ""): \(text)\n")
            }
        case "353":
            if let params = message.params, channelIndex = params.characters.indexOf({ "@=*".containsString(String($0)) }), nicksIndex = params.characters.indexOf(":") {
                let channelName = params.substringWithRange(channelIndex.successor()..<nicksIndex).trim()
                let nicks = params.substringFromIndex(nicksIndex.successor()).trim().split(" ")
                let channel = getChannel(channelName, contents: nil)
                channel.users.unionInPlace(nicks)
                channels.rearrangeObjects()
            }
        case "332":
            if let params = message.params, channelIndex = params.characters.indexOf(" "), topicIndex = params.characters.indexOf(":") {
                let channel = params.substringWithRange(channelIndex..<topicIndex).trim()
                let topic = params.substringFromIndex(topicIndex.successor()).trim()
                appendMessageToChannel(channel, message: "\(topic)\n")
            }
        default:
            break
        }

        scrollIfNeeded()
    }

    func didReceiveStringMessage(message: String) {
        (channels.arrangedObjects as? Array<Channel>)?.forEach { appendMessageToChannel($0.name, message: message) }

        scrollIfNeeded()
    }

    func didReceiveError(error: NSError) {
        NSAlert(error: error).runModal()
    }

}
