//
//  StatusBarController.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 27/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Cocoa

enum MenuItem: Int {
    case Separator = -1
    case Title = 0
    case Update
    case Generate
    case SoundEnabled
    case CamelCaseConversion
    case Preferences
    case Restart
    case Quit
}

class StatusBarController: NSObject, NSMenuDelegate {

    let statusMenu = NSMenu()
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)

    var preferencesController: PreferencesController?

    override init() {
        super.init()

        statusMenu.delegate = self

        setupStatusItems()
        updateMenuItems()
    }

    func setupStatusItems() {
        // Setup image and menu
        statusItem.button?.image = NSImage(named: "bat")
        statusItem.menu = statusMenu

        // Title item
        if let infoDict = NSBundle.mainBundle().infoDictionary {
            let version = infoDict["CFBundleShortVersionString"]!
            let build   = infoDict["CFBundleVersion"]!
            let name    = infoDict["CFBundleName"]!

            let versionItem = NSMenuItem(title: "\(name) v\(version) (\(build))", action: "", keyEquivalent: "")
            versionItem.tag = MenuItem.Title.rawValue
            statusMenu.addItem(versionItem)
        }

        // Menu item for generation
        let generateItem = NSMenuItem(title: "Current hotkey: ", action: "", keyEquivalent: "")
        generateItem.tag = MenuItem.Generate.rawValue
        statusMenu.addItem(generateItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.Separator.rawValue))

        // Add section title
        statusMenu.addItem(NSMenuItem(title: "Options:", action: "", keyEquivalent: ""))

        // Camel case conversion item
        let camelCaseItem    = NSMenuItem(title: "camelCase -> underscore_notation", action: "toggleCamelCaseConversion", keyEquivalent: "")
        camelCaseItem.state  = SettingsManager.isSettingEnabled(.NoCamelCaseConversion) ? NSOffState : NSOnState
        camelCaseItem.target = self
        camelCaseItem.tag    = MenuItem.CamelCaseConversion.rawValue
        statusMenu.addItem(camelCaseItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.Separator.rawValue))

        // Sound enabled item
        let soundItem    = NSMenuItem(title: "Audio enabled", action: "toggleSoundEnabled", keyEquivalent: "")
        soundItem.state  = SettingsManager.isSettingEnabled(.SoundEnabled) ? NSOnState : NSOffState
        soundItem.target = self
        soundItem.tag    = MenuItem.SoundEnabled.rawValue
        statusMenu.addItem(soundItem)

        // Preferences item
        let preferencesItem = NSMenuItem(title: "Settings", action: "showSettings", keyEquivalent: "")
        preferencesItem.target = self
        preferencesItem.tag    = MenuItem.Preferences.rawValue
        statusMenu.addItem(preferencesItem)

        // Check for updates item
        let updateItem    = NSMenuItem(title: "Check for updates", action: "updatePressed", keyEquivalent: "")
        updateItem.target = self
        updateItem.tag    = MenuItem.Update.rawValue
        statusMenu.addItem(updateItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.Separator.rawValue))

        // Restart item
        let restartItem = NSMenuItem(title: "Restart", action: "restartPressed", keyEquivalent: "")
        restartItem.tag = MenuItem.Restart.rawValue
        restartItem.target = self
        statusMenu.addItem(restartItem)

        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: "quitPressed", keyEquivalent: "")
        quitItem.tag = MenuItem.Quit.rawValue
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    func updateMenuItems() {
        for menuItem in statusMenu.itemArray {
            guard let item = MenuItem(rawValue: menuItem.tag) else { continue }
            switch item {
            case .Generate:
                if let keyCommand = KeyCommandManager.currentKeyCommand() {
                    menuItem.keyEquivalent = keyCommand.command
                    menuItem.keyEquivalentModifierMask = Int(keyCommand.modifierMask.rawValue)
                }
            case .CamelCaseConversion:
                menuItem.state = SettingsManager.isSettingEnabled(.NoCamelCaseConversion) ? NSOffState : NSOnState
            case .SoundEnabled:
                menuItem.state = SettingsManager.isSettingEnabled(.SoundEnabled) ? NSOnState : NSOffState
            default: break
            }
        }
    }

    // MARK: - Callbacks -

    func generate(pboard:NSPasteboard!, userData:NSString!, error:AutoreleasingUnsafeMutablePointer<NSString?>) -> Void {
        Service.generate(pboard)
    }

    func updatePressed() {
        UpdateManager.sharedInstance.checkForUpdates()
    }

    func toggleSoundEnabled() {
        let newState = !SettingsManager.isSettingEnabled(.SoundEnabled)
        SettingsManager.setSetting(.SoundEnabled, enabled: newState)

        if let soundItem = statusMenu.itemWithTag(MenuItem.SoundEnabled.rawValue) {
            soundItem.state = newState == true ? NSOnState : NSOffState
        }
    }

    func toggleCamelCaseConversion() {
        let newState = !SettingsManager.isSettingEnabled(.NoCamelCaseConversion)
        SettingsManager.setSetting(.NoCamelCaseConversion, enabled: newState)

        if let camelCaseItem = statusMenu.itemWithTag(MenuItem.CamelCaseConversion.rawValue) {
            camelCaseItem.state = newState == true ? NSOffState : NSOnState
        }
    }

    func showSettings() {
        preferencesController = PreferencesController.newFromNib()
        preferencesController?.window?.makeKeyFrontAndCenter(self)
        NSApp.activateIgnoringOtherApps(true)
    }

    func restartPressed() {
        NSApplication.sharedApplication().restart()
    }

    func quitPressed() {
        NSApplication.sharedApplication().terminate(self)
    }

    // MARK: - NSMenu Delegate -

    func menuWillOpen(menu: NSMenu) {
        updateMenuItems()
    }
}
