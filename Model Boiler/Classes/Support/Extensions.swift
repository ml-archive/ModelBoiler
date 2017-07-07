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
    @objc static func display(title: String, andMessage message: String) {
        dispatch(background: false) {
            let notification             = NSUserNotification()
            notification.title           = title
            notification.informativeText = message
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
}

extension NSApplication {
    @objc func terminateAlreadyRunningInstances() {
        guard let identifier = Bundle.main.bundleIdentifier else { return }

        // Terminate all previously running apps with same bundle identifier
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
        for runningApp in runningApps {
            if !runningApp.isEqual(NSRunningApplication.current) {
                runningApp.terminate()
            }
        }
    }

    @objc func verifyAppInstallLocation() {
        if !isInApplications() && !isInBrewsFolder() {

            let alert = NSAlert()
            alert.addButton(withTitle: "Install in Applications folder")
            alert.addButton(withTitle: "Quit")
            alert.messageText     = "Install in Application folder?"
            alert.informativeText = "The app should be in your Applications folder in order to work properly."
            let response = alert.runModal()

            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
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

    @objc func isInApplications() -> Bool {
        let sourcePath = Bundle.main.bundlePath
        let appFolders = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)

        guard let folder = appFolders.first, let appName = sourcePath.components(separatedBy: "/").last else {
            return true
        }

        let expectedPath = folder + "/" + appName

        return sourcePath == expectedPath
    }
    
    @objc func isInBrewsFolder() -> Bool {
        let sourcePath = Bundle.main.bundlePath
        
        return sourcePath.contains("homebrew-cask/Caskroom")
    }

    @objc func moveToApplicationsIfNecessary() throws {
        if isInApplications() || isInBrewsFolder() { return }

        let bundle     = Bundle.main
        let sourcePath = bundle.bundlePath
        let appFolders = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)

        guard let folder = appFolders.first, let appName = sourcePath.components(separatedBy: "/").last else {
            throw NSError(domain: bundle.bundleIdentifier ?? "", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Applications folder not found."])
        }

        let expectedPath = folder + "/" + appName
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: expectedPath) {
            try fileManager.removeItem(atPath: expectedPath)
        }

        try fileManager.moveItem(atPath: sourcePath, toPath: expectedPath)
    }

    @objc func restart() {
        let task = Process()
        task.launchPath = Bundle.main.path(forResource: "relaunch", ofType: nil)!
        task.arguments = [String(ProcessInfo.processInfo.processIdentifier)]
        task.launch()
    }
}

extension URLRequest {
    static func requestForGithubWithPath(_ path: String) -> URLRequest? {
        guard let URL = URL(string: "https://api.github.com/\(path)") else {
            return nil
        }

        var request = URLRequest(url: URL)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return request
    }
}

extension NSMenuItem {
    @objc static func separatorItemWithTag(_ tag: Int) -> NSMenuItem {
        let separatorItem = NSMenuItem.separator()
        separatorItem.tag = tag
        return separatorItem
    }
}

extension NSWindow {
    @objc func makeKeyFrontAndCenter(_ sender: AnyObject?) {
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
    func versionToArray(_ version: String) -> [Int] {
        return version.components(separatedBy: ".").map {
            Int($0) ?? 0
        }
    }

    func isBiggerThanVersion(_ version: String) -> Bool {
        let aVer = versionToArray(self)
        let bVer = versionToArray(version)

        return bVer.lexicographicallyPrecedes(aVer)
    }
}

func dispatch(background: Bool = false, closure: @escaping () -> Void) {
    let queue = background ? DispatchQueue.global(qos: DispatchQoS.QoSClass.utility) : DispatchQueue.main
    queue.async(execute: {
        closure()
    })
}

func delay(_ delay: Int64, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(delay * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
        closure()
    })
}
