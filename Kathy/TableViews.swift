//
//  TableViews.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa


class ChannelView: NSScrollView, NSTableViewDelegate {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let tableView = NSTableView()
        tableView.identifier = "channelView"
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.addTableColumn(NSTableColumn())
        tableView.headerView = nil
        tableView.setDelegate(self)
        documentView = tableView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let textField = NSTextField()
        textField.bordered = false
        textField.drawsBackground = false
        textField.editable = false
        textField.bind("value", toObject: textField, withKeyPath: "objectValue", options: nil)

        return textField
    }

}

class UserView: NSScrollView, NSTableViewDelegate {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let tableView = NSTableView()
        tableView.identifier = "userView"
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.addTableColumn(NSTableColumn())
        tableView.headerView = nil
        tableView.setDelegate(self)
        documentView = tableView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let textField = NSTextField()
        textField.bordered = false
        textField.drawsBackground = false
        textField.editable = false
        textField.bind("value", toObject: textField, withKeyPath: "objectValue", options: nil)

        return textField
    }

}
