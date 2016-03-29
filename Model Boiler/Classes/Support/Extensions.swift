//
//  Extensions.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 25/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation
import Cocoa

extension NSUserNotification {
    static func display(title title: String, andMessage message: String) {
        dispatch(background: false) {
            let notification             = NSUserNotification()
            notification.title           = title
            notification.informativeText = message
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
    }
}

extension NSApplication {
    func terminateAlreadyRunningInstances() {
        guard let identifier = NSBundle.mainBundle().bundleIdentifier else { return }

        // Terminate all previously running apps with same bundle identifier
        let runningApps = NSRunningApplication.runningApplicationsWithBundleIdentifier(identifier)
        for runningApp in runningApps {
            if !runningApp.isEqual(NSRunningApplication.currentApplication()) {
                runningApp.terminate()
            }
        }
    }

    func verifyAppInstallLocation() {
        if !isInApplications() {

            let alert = NSAlert()
            alert.addButtonWithTitle("Install in Applications folder")
            alert.addButtonWithTitle("Quit")
            alert.messageText     = "Install in Application folder?"
            alert.informativeText = "The app should be in your Applications folder in order to work properly."
            let response = alert.runModal()

            if response == NSAlertFirstButtonReturn {
                do {
                    try moveToApplicationsIfNecessary()
                    restart()
                } catch {
                    let errorAlert = NSAlert()
                    errorAlert.messageText     = "An error happened, the app will now quit."
                    errorAlert.informativeText = (error as NSError).localizedDescription
                    errorAlert.runModal()
                    self.terminate(self)
                }
            } else {
                self.terminate(self)
            }
        }
    }

    func isInApplications() -> Bool {
        let sourcePath = NSBundle.mainBundle().bundlePath
        let appFolders = NSSearchPathForDirectoriesInDomains(.ApplicationDirectory, .LocalDomainMask, true)

        guard let folder = appFolders.first, appName = sourcePath.componentsSeparatedByString("/").last else {
            return true
        }

        let expectedPath = folder + "/" + appName

        return sourcePath == expectedPath
    }
    
    func isInBrewsFolder() -> Bool {
        let sourcePath = NSBundle.mainBundle().bundlePath
        
        return sourcePath.containsString("homebrew-cask/Caskroom")
    }

    func moveToApplicationsIfNecessary() throws {
        if isInApplications() || isInBrewsFolder() { return }

        let bundle     = NSBundle.mainBundle()
        let sourcePath = bundle.bundlePath
        let appFolders = NSSearchPathForDirectoriesInDomains(.ApplicationDirectory, .LocalDomainMask, true)

        guard let folder = appFolders.first, appName = sourcePath.componentsSeparatedByString("/").last else {
            throw NSError(domain: bundle.bundleIdentifier ?? "", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Applications folder not found."])
        }

        let expectedPath = folder + "/" + appName
        let fileManager = NSFileManager.defaultManager()

        if fileManager.fileExistsAtPath(expectedPath) {
            try fileManager.removeItemAtPath(expectedPath)
        }

        try fileManager.moveItemAtPath(sourcePath, toPath: expectedPath)
    }

    func restart() {
        let task = NSTask()
        task.launchPath = NSBundle.mainBundle().pathForResource("relaunch", ofType: nil)!
        task.arguments = [String(NSProcessInfo.processInfo().processIdentifier)]
        task.launch()
    }
}

extension NSMutableURLRequest {
    static func requestForGithubWithPath(path: String) -> NSMutableURLRequest? {
        guard let URL = NSURL(string: "https://api.github.com/\(path)") else {
            return nil
        }

        let request = NSMutableURLRequest(URL: URL)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return request
    }
}

extension NSMenuItem {
    static func separatorItemWithTag(tag: Int) -> NSMenuItem {
        let separatorItem = NSMenuItem.separatorItem()
        separatorItem.tag = tag
        return separatorItem
    }
}

extension NSWindow {
    func makeKeyFrontAndCenter(sender: AnyObject?) {
        makeKeyAndOrderFront(sender)

        if let screen = self.screen {
            let screenFrame = screen.frame
            let windowFrame = frame

            let xPos = screenFrame.width / 2 - windowFrame.width / 2
            let yPos = screenFrame.height / 2 - windowFrame.height / 2

            setFrame(NSMakeRect(xPos, yPos, windowFrame.size.width, windowFrame.size.height), display: true)
        }
    }
}

extension String {
    func versionToArray(version: String) -> [Int] {
        return version.componentsSeparatedByString(".").map {
            Int($0) ?? 0
        }
    }

    func isBiggerThanVersion(version: String) -> Bool {
        let aVer = versionToArray(self)
        let bVer = versionToArray(version)

        return bVer.lexicographicalCompare(aVer)
    }
}

func dispatch(background background: Bool = false, closure: () -> Void) {
    let queue = background ? dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) : dispatch_get_main_queue()
    dispatch_async(queue, {
        closure()
    })
}

func delay(delay: Int64, closure: () -> Void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, delay * Int64(NSEC_PER_SEC)),
        dispatch_get_main_queue(), {
        closure()
    })
}