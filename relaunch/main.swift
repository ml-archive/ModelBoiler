//
//  main.swift
//  relaunch
//
//  Created by Dominik Hádl on 11/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import AppKit

// KVO helper
class Observer: NSObject {

    let _callback: () -> Void

    init(callback: @escaping () -> Void) {
        _callback = callback
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        _callback()
    }
}


// main
autoreleasepool {

    // the application pid
    let parentPID = atoi(CommandLine.arguments[1])

    // get the application instance
    if let app = NSRunningApplication(processIdentifier: parentPID) {

        // application URL
        let bundleURL = app.bundleURL!

        // terminate() and wait terminated.
        let listener = Observer { CFRunLoopStop(CFRunLoopGetCurrent()) }
        app.addObserver(listener, forKeyPath: "isTerminated", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        app.terminate()
        CFRunLoopRun() // wait KVO notification
        app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)

        // relaunch
        do {
            try NSWorkspace.shared.launchApplication(
                    at: bundleURL,
                    options: NSWorkspace.LaunchOptions(rawValue: 0),
                    configuration: [:])
        } catch {
            print("Error relaunching")
        }
    }
}
