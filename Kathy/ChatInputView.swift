//
//  ChatInputView.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

extension ChatView: NSTextFieldDelegate {

    func resetHistoryIndex() {
        if let history = userDefaults.arrayForKey("history") as? [String] {
            historyIndex = history.count - 1
        }
    }

    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        if let history = userDefaults.arrayForKey("history") as? [String] {
            if commandSelector == #selector(moveUp) {
                control.stringValue = history[historyIndex]
                historyIndex = max(historyIndex - 1, 0)
                control.currentEditor()?.moveToEndOfLine(nil)
                return true
            }

            if commandSelector == #selector(moveDown) {
                historyIndex = min(historyIndex + 1, history.count - 1)
                control.stringValue = history[historyIndex]
                control.currentEditor()?.moveToEndOfLine(nil)
                return true
            }

            if commandSelector == #selector(insertTab) {
                control.currentEditor()?.complete(nil)
                return true
            }
        }
        return false
    }

    func control(control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        return (channels.selectedObjects.first as? Channel)?.users
            .map { return $0.name + ": " }
            .filter { $0.hasPrefix(control.stringValue) } ?? []
    }

    override func controlTextDidEndEditing(obj: NSNotification) {
        guard let inputField = obj.object as? NSTextField else { return }
        guard inputField.stringValue.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()) != "" else { return }
        defer { inputField.stringValue = "" }

        let text = inputField.stringValue
        if text.hasPrefix("/") {
            session?.command(text)
        } else {
            if let channel = channels.selectedObjects.first as? Channel {
                if channel != console {
                    session?.command("/PRIVMSG \(channel.name) :\(text)")
                    appendMessageToActiveChannel("\(nick): \(text)\n")
                } else {
                    appendMessageToActiveChannel("\(text)\n")
                }
            }
        }

        if var history = userDefaults.arrayForKey("history") as? [String] {
            if let index = history.indexOf(text) {
                history.removeAtIndex(index)
            }
            history.append(text)
            userDefaults.setObject(history, forKey: "history")
        }
        resetHistoryIndex()
    }

}
