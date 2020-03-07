//
//  Service.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 25/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation
import Cocoa
import SwiftSyntax
import SwiftSemantics

class Generator {
    
    let source: String
    
    init(source: String) {
        self.source = source
    }
    
     var encode: [String] = ["""
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    """
        ]
        
        var initStrings: [String] = ["""
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
        """
        ]
        
        var codingKeys: [String] = ["""
            enum CodingKeys: String, CodingKey {
            """
        ]
        
    func addNode(name: String, type: String, isOptional: Bool = false) {
           encode.append("    try container.encode(\(name), forKey: .\(name))")
           if isOptional {
               initStrings.append("    \(name) = try container.decodeIfPresent(\(type).self, forKey: .\(name))")
           } else {
               initStrings.append("    \(name) = try container.decode(\(type).self, forKey: .\(name))")
           }
           codingKeys.append("    case \(name) = \"\(name)\"")
       }
    
    func generate() throws -> String {
        var collector = DeclarationCollector()
        let tree = try SyntaxParser.parse(source: source)
        tree.walk(&collector)

        for v in collector.variables {
            addNode(name: v.name, type: v.typeAnnotation!, isOptional: v.typeAnnotation!.contains("?"))
        }

        encode.append("}\n")
        initStrings.append("}")
        codingKeys.append("}\n")
        
        return codingKeys.joined(separator: "\n") + encode.joined(separator: "\n") + initStrings.joined(separator: "\n")
    }
}

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
//        var generatorSettings = ModelGeneratorSettings()
//        generatorSettings.moduleName = nil
//        generatorSettings.noConvertCamelCase = SettingsManager.isSettingEnabled(.NoCamelCaseConversion)
//        generatorSettings.useNativeDictionaries = SettingsManager.isSettingEnabled(.UseNativeDictionaries)
//        generatorSettings.onlyCreateInitializer = SettingsManager.isSettingEnabled(.OnlyCreateInitializer)
//        
        do {
            // Try to generate the code
            let code = try Generator(source: source).generate()

            // Play success sound
            playSound(Service.successSound)

            // Copy back to pasteboard
            
            NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            NSPasteboard.general.setString(code, forType: NSPasteboard.PasteboardType.string)

            // Success, show notification
            NSUserNotification.display(
                title: "Code generated",
                andMessage: "The code has been copied to the clipboard.")
        } catch {

            // Show error notification
            NSUserNotification.display(
                title: "Code generation failed",
                andMessage: "Error: \(error.localizedDescription) ")

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
