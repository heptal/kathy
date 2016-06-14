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

    @IBAction func openPreferences(sender: AnyObject) {
        PreferencesWindowController.singleton.showWindow(nil)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self

        NSUserDefaults.standardUserDefaults().registerDefaults([
            "nick": "test0rz",
            "user": "test0rz",
            "invisible": false,
            "autoConnect:": true,
            "defaultHost": "irc.freenode.net",
            "history": ["/server irc.freenode.net"],
            ])

        ChatWindowController.singleton.showWindow(nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        ChatWindowController.singleton.showWindow(nil)
        return true
    }

}

extension AppDelegate: NSUserNotificationCenterDelegate {

    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        ChatWindowController.singleton.showWindow(nil)
    }

}
