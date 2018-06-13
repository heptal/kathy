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
        if let history = userDefaults.array(forKey: "history") as? [String] {
            historyIndex = history.count - 1
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if let history = userDefaults.array(forKey: "history") as? [String] {
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

    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        return (session.channels.selectedObjects.first as? Channel)?.users
            .map { return $0.name + ": " }
            .filter { $0.hasPrefix(control.stringValue) } ?? []
    }

    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let inputField = obj.object as? NSTextField else { return }
        guard inputField.stringValue.trimmingCharacters(in: .whitespaces) != "" else { return }
        defer { inputField.stringValue = "" }

        let text = inputField.stringValue
        if text.hasPrefix("/") {
            session?.command(text)
        } else {
            if let channel = session.channels.selectedObjects.first as? Channel {
                if channel.name != session.consoleChannelName {
                    session?.command("/PRIVMSG \(channel.name) :\(text)")
                    let message = "\(session.currentNick): \(text)\n"
                    channel.log.append(message)
                    appendMessageToActiveChannel(message)

                } else {
                    let message = text + "\n"
                    channel.log.append(message)
                    appendMessageToActiveChannel(message)
                }
            }
        }

        if var history = userDefaults.array(forKey: "history") as? [String] {
            if let index = history.index(of: text) {
                history.remove(at: index)
            }
            history.append(text)
            userDefaults.set(history, forKey: "history")
        }

        resetHistoryIndex()
    }

}
