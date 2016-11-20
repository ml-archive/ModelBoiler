//
//  PreferencesController.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 26/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Cocoa
import MASShortcut

class PreferencesController: NSWindowController {

    @IBOutlet var shortcutView: MASShortcutView!
    @IBOutlet var nativeDictionariesSwitch: NSButton!

    class func newFromNib() -> PreferencesController {
        return PreferencesController(windowNibName: "Preferences")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        loadSettings()
        loadSavedKeyCommand()

        shortcutView.associatedUserDefaultsKey = "MASShortcutKey"
        shortcutView.shortcutValueChange = { (view) in
            self.updateServiceKeyCommand()
        }
    }

    func loadSavedKeyCommand() {
        if let keyCommand = KeyCommandManager.currentKeyCommand() {
            let scalars = keyCommand.command.unicodeScalars
            let keyCode = UInt(scalars[scalars.startIndex].value)

            let shortcut = MASShortcut(keyCode: keyCode, modifierFlags: keyCommand.modifierMask.rawValue)
            shortcutView.shortcutValue = shortcut
        }
    }

    func updateServiceKeyCommand() {
        let keyCode  = self.shortcutView.shortcutValue.keyCodeString
        let modifier = NSEventModifierFlags(rawValue: self.shortcutView.shortcutValue.modifierFlags)
        guard let code = keyCode else {
            loadSavedKeyCommand()
            return
        }

        do {
            try KeyCommandManager.updateKeyCommand(code, modifierMask: modifier)
        } catch {
            // Update failed, revert back
            loadSavedKeyCommand()
        }
    }

    @IBAction func switchChanged(_ sender: NSButton) {
        if sender == nativeDictionariesSwitch {
            let state = (sender.state == NSOnState)
            SettingsManager.setSetting(.UseNativeDictionaries, enabled: state)
        }
    }

    func loadSettings() {
        nativeDictionariesSwitch.state = SettingsManager.isSettingEnabled(.UseNativeDictionaries) ? NSOnState : NSOffState
    }
}
