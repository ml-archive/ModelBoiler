//
//  StatusBarController.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 27/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Cocoa

enum MenuItem: Int {
    case separator = -1
    case title = 0
    case update
    case generate
    case soundEnabled
    case camelCaseConversion
    case onlyCreateInitializer
    case preferences
    case restart
    case quit
}

class StatusBarController: NSObject, NSMenuDelegate {

    let statusMenu  = NSMenu()
    let optionsMenu = NSMenu()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var preferencesController: PreferencesController?

    override init() {
        super.init()

        statusMenu.delegate = self

        setupStatusItems()
        updateMenuItems()
    }

    func setupStatusItems() {
        // Setup image and menu
        statusItem.button?.image = NSImage(named: NSImage.Name(rawValue: "bat"))
        statusItem.menu = statusMenu

        // Title item
        if let infoDict = Bundle.main.infoDictionary {
            let version = infoDict["CFBundleShortVersionString"]!
            let build   = infoDict["CFBundleVersion"]!
            let name    = infoDict["CFBundleName"]!

            let versionItem = NSMenuItem(title: "\(name) v\(version) (\(build))", action: nil, keyEquivalent: "")
            versionItem.tag = MenuItem.title.rawValue
            statusMenu.addItem(versionItem)
        }

        // Menu item for generation
        let generateItem = NSMenuItem(title: "Current hotkey: ", action: nil, keyEquivalent: "")
        generateItem.tag = MenuItem.generate.rawValue
        statusMenu.addItem(generateItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.separator.rawValue))

        // Add options menu
        let optionsItem = NSMenuItem( title: "Options", action: nil, keyEquivalent: "")
        statusMenu.addItem(optionsItem)
        statusMenu.setSubmenu(optionsMenu, for: optionsItem)
        
        // Camel case conversion item
        let camelCaseItem    = NSMenuItem(title: "Map camelCase -> underscore_notation", action: #selector(toggleCamelCaseConversion), keyEquivalent: "")
        camelCaseItem.state  = SettingsManager.isSettingEnabled(.NoCamelCaseConversion) ? NSControl.StateValue.offState : NSControl.StateValue.onState
        camelCaseItem.target = self
        camelCaseItem.tag    = MenuItem.camelCaseConversion.rawValue
        optionsMenu.addItem(camelCaseItem)

        // Sound enabled item
        let soundItem    = NSMenuItem(title: "Audio enabled", action: #selector(StatusBarController.toggleSoundEnabled), keyEquivalent: "")
        soundItem.state  = SettingsManager.isSettingEnabled(.SoundEnabled) ? NSControl.StateValue.onState : NSControl.StateValue.offState
        soundItem.target = self
        soundItem.tag    = MenuItem.soundEnabled.rawValue
        optionsMenu.addItem(soundItem)
        
        // Generate Initializer only
        let initializerOnlyItem    = NSMenuItem(title: "Only generate initializer (useful for use with Realm/CoreData)", action: #selector(toggleOnlyCreateInitializers), keyEquivalent: "")
        initializerOnlyItem.state  = SettingsManager.isSettingEnabled(.OnlyCreateInitializer) ? NSControl.StateValue.onState : NSControl.StateValue.offState
        initializerOnlyItem.target = self
        initializerOnlyItem.tag    = MenuItem.onlyCreateInitializer.rawValue
        optionsMenu.addItem(initializerOnlyItem)
        
        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.separator.rawValue))
        
        // Preferences item
        let preferencesItem = NSMenuItem(title: "Settings", action: #selector(StatusBarController.showSettings), keyEquivalent: "")
        preferencesItem.target = self
        preferencesItem.tag    = MenuItem.preferences.rawValue
        statusMenu.addItem(preferencesItem)

        // Check for updates item
        let updateItem    = NSMenuItem(title: "Check for updates", action: #selector(StatusBarController.updatePressed), keyEquivalent: "")
        updateItem.target = self
        updateItem.tag    = MenuItem.update.rawValue
        statusMenu.addItem(updateItem)

        // Separator
        statusMenu.addItem(NSMenuItem.separatorItemWithTag(MenuItem.separator.rawValue))

        // Restart item
        let restartItem = NSMenuItem(title: "Restart", action: #selector(StatusBarController.restartPressed), keyEquivalent: "")
        restartItem.tag = MenuItem.restart.rawValue
        restartItem.target = self
        statusMenu.addItem(restartItem)

        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(StatusBarController.quitPressed), keyEquivalent: "")
        quitItem.tag = MenuItem.quit.rawValue
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    func updateMenuItems() {
        for menuItem in statusMenu.items {
            guard let item = MenuItem(rawValue: menuItem.tag) else { continue }
            switch item {
            case .generate:
                if let keyCommand = KeyCommandManager.currentKeyCommand() {
                    menuItem.keyEquivalent = keyCommand.command
                    menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(Int(keyCommand.modifierMask.rawValue)))
                }
            case .camelCaseConversion:
                menuItem.state = SettingsManager.isSettingEnabled(.NoCamelCaseConversion) ? NSControl.StateValue.offState : NSControl.StateValue.onState
            case .soundEnabled:
                menuItem.state = SettingsManager.isSettingEnabled(.SoundEnabled) ? NSControl.StateValue.onState : NSControl.StateValue.offState
            default: break
            }
        }
    }

    // MARK: - Callbacks -

    @objc func generate(_ pboard:NSPasteboard!, userData:NSString!, error:AutoreleasingUnsafeMutablePointer<NSString?>) -> Void {
        Service.generate(pboard)
    }

    @objc func updatePressed() {
        UpdateManager.sharedInstance.checkForUpdates()
    }

    @objc func toggleSoundEnabled() {
        let newState = !SettingsManager.isSettingEnabled(.SoundEnabled)
        SettingsManager.setSetting(.SoundEnabled, enabled: newState)

        if let soundItem = optionsMenu.item(withTag: MenuItem.soundEnabled.rawValue) {
            soundItem.state = newState == true ? NSControl.StateValue.onState : NSControl.StateValue.offState
        }
    }

    @objc func toggleCamelCaseConversion() {
        let newState = !SettingsManager.isSettingEnabled(.NoCamelCaseConversion)
        SettingsManager.setSetting(.NoCamelCaseConversion, enabled: newState)

        if let camelCaseItem = optionsMenu.item(withTag: MenuItem.camelCaseConversion.rawValue) {
            camelCaseItem.state = newState == true ? NSControl.StateValue.offState : NSControl.StateValue.onState
        }
    }
    
    @objc func toggleOnlyCreateInitializers() {
        let newState = !SettingsManager.isSettingEnabled(.OnlyCreateInitializer)
        SettingsManager.setSetting(.OnlyCreateInitializer, enabled: newState)
        
        if let camelCaseItem = optionsMenu.item(withTag: MenuItem.onlyCreateInitializer.rawValue) {
            camelCaseItem.state = newState == true ? NSControl.StateValue.onState : NSControl.StateValue.offState
        }
    }
    
    @objc func showSettings() {
        preferencesController = PreferencesController.newFromNib()
        preferencesController?.window?.makeKeyFrontAndCenter(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func restartPressed() {
        NSApplication.shared.restart()
    }

    @objc func quitPressed() {
        NSApplication.shared.terminate(self)
    }

    // MARK: - NSMenu Delegate -

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuItems()
    }
}
