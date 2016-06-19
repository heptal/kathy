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
        users.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        users.automaticallyRearrangesObjects = true
        let userTableView = userView.subviewWithIdentifier("userView") as? NSTableView
        userTableView?.bind("content", toObject: users, withKeyPath: "arrangedObjects.description", options: nil)

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
        case "PRIVMSG":
            if let nick = message.prefix?.nick, matches = "(\\S+) :?(.*)".captures(message.params), text = matches.last, var channel = matches.first {
                if channel == self.nick {
                    channel = nick

                    let notification = NSUserNotification()
                    notification.title = "Message from \(nick)"
                    notification.informativeText = text
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
                appendMessageToChannel(channel, message: "\(nick): \(text)\n")
            }
        case "JOIN":
            if let channelName = message.params, nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == self.nick ? "You have" : "\(nick) has") + " joined the channel\n")
                getChannel(channelName, contents: nil).users.insert(User(nick))
                channels.rearrangeObjects()
            }
        case "PART":
            if let channelName = message.params, nick = message.prefix?.nick {
                appendMessageToChannel(channelName, message: (nick == self.nick ? "You have" : "\(nick) has") + " left the channel\n")
                getChannel(channelName, contents: nil).users.remove(User(nick))
                channels.rearrangeObjects()
            }
        case "353":
            if let matches = "\\S+ [@=*] (\\S+) :?(.*) ?".captures(message.params), channelName = matches.first, nicks = matches.last?.split(" ") {
                let channel = getChannel(channelName, contents: nil)
                channel.users.unionInPlace(nicks.map { User($0) })
                channels.rearrangeObjects()
            }
        case "332":
                if let matches = "\\S+ (\\S+) :?(.*) ?".captures(message.params), channel = matches.first, topic = matches.last {
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
