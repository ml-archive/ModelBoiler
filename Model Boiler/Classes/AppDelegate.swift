//
//  AppDelegate.swift
//  Model Boiler
//
//  Created by Kasper Welner on 09/08/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let mainController = StatusBarController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Stop already running instances
        NSApp.terminateAlreadyRunningInstances()

        #if RELEASE
        // Check if installed in applications folder
        NSApp.verifyAppInstallLocation()
        #endif

        // Update services
        NSApp.servicesProvider = mainController
        NSUpdateDynamicServices()

        // If first launch, then set default key command
        if !SettingsManager.isSettingEnabled(.AppWasOpened) {
            SettingsManager.setSetting(.AppWasOpened, enabled: true)
            KeyCommandManager.setDefaultKeyCommand()
        }

        // Start checking for updates
        UpdateManager.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        UpdateManager.stop()
    }
}
