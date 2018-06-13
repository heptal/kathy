//
//  AppDelegate.swift
//  Kathy
//
//  Created by Michael Bujol on 6/13/16.
//  Copyright © 2016 heptal. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func openPreferences(_ sender: AnyObject) {
        PreferencesWindowController.singleton.showWindow(nil)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self

        UserDefaults.standard.register(defaults: [
            "nick": "test0rz",
            "user": "test0rz",
            "invisible": false,
            "autoConnect:": true,
            "defaultHost": "irc.freenode.net",
            "history": ["/server irc.freenode.net"],
            ])

        ChatWindowController.singleton.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        ChatWindowController.singleton.showWindow(nil)
        return true
    }

}

extension AppDelegate: NSUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        ChatWindowController.singleton.showWindow(nil)
    }

}
