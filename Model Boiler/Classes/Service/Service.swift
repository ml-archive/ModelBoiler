//
//  Service.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 25/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation
import ModelGenerator
import Cocoa

struct Service {

    static let errorSound   = NSSound(named: "Basso")
    static let successSound = NSSound(named: "Pop")

    // MARK: - Main Function -

    static func generate(pasteboard: NSPasteboard = NSPasteboard.generalPasteboard()) {

        guard let source = pasteboard.stringForType(NSPasteboardTypeString) where (pasteboard.pasteboardItems?.count == 1) else {
            NSUserNotification.display(title: "No text selected",
                andMessage: "Nothing was found in the pasteboard.")
            playSound(Service.errorSound)
            return
        }

        // Setup the model generator
        var generatorSettings = ModelGeneratorSettings()
        generatorSettings.moduleName = nil
        generatorSettings.noConvertCamelCase = SettingsManager.isSettingEnabled(.NoCamelCaseConversion)
        generatorSettings.useNativeDictionaries = SettingsManager.isSettingEnabled(.UseNativeDictionaries)

        do {
            // Try to generate the code
            let code = try ModelGenerator.modelCodeFromSourceCode(source, withSettings: generatorSettings)

            // Play success sound
            playSound(Service.successSound)

            // Copy back to pasteboard
            NSPasteboard.generalPasteboard().declareTypes([NSPasteboardTypeString], owner: nil)
            NSPasteboard.generalPasteboard().setString(code, forType: NSPasteboardTypeString)

            // Success, show notification
            NSUserNotification.display(
                title: "Code generated",
                andMessage: "The code has been copied to the clipboard.")
        } catch {

            // Show error notification
            NSUserNotification.display(
                title: "Code generation failed",
                andMessage: "Error: \((error as? ModelGeneratorErrorType)?.description() ?? "Unknown error.")")

            // Play error sound
            playSound(Service.errorSound)
        }
    }

    // MARK: - Helpers -

    static func playSound(sound: NSSound?) {
        if !NSUserDefaults.standardUserDefaults().boolForKey("muteSound") {
            sound?.play()
        }
    }
}
