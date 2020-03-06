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

    static func generate(_ pasteboard: NSPasteboard = NSPasteboard.general) {

        guard let source = pasteboard.string(forType: NSPasteboard.PasteboardType.string), (pasteboard.pasteboardItems?.count == 1) else {
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
        generatorSettings.onlyCreateInitializer = SettingsManager.isSettingEnabled(.OnlyCreateInitializer)
        
        do {
            // Try to generate the code
            let code = try ModelGenerator.modelCode(fromSourceCode: source, withSettings: generatorSettings)

            // Play success sound
            playSound(Service.successSound)

            // Copy back to pasteboard
            NSPasteboard.general.declareTypes(convertToNSPasteboardPasteboardTypeArray([convertFromNSPasteboardPasteboardType(NSPasteboard.PasteboardType.string)]), owner: nil)
            NSPasteboard.general.setString(code, forType: NSPasteboard.PasteboardType.string)

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

    static func playSound(_ sound: NSSound?) {
        if !UserDefaults.standard.bool(forKey: "muteSound") {
            sound?.play()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSPasteboardPasteboardTypeArray(_ input: [String]) -> [NSPasteboard.PasteboardType] {
	return input.map { key in NSPasteboard.PasteboardType(key) }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSPasteboardPasteboardType(_ input: NSPasteboard.PasteboardType) -> String {
	return input.rawValue
}
