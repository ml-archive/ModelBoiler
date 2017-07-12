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
    
    static let errorSound   = NSSound(named: NSSound.Name(rawValue: "Basso"))
    static let successSound = NSSound(named: NSSound.Name(rawValue: "Pop"))
    
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
            // Try to generate the code bodies
            guard let extensions = try extensionBodies(fromSource: source, generatorSettings: generatorSettings) else { throw ModelParserError.NoModelNameFound }
            
            //Concatenate the extensions
            let code = extensionCode(fromBodies: extensions)
            
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
                andMessage: "Error: \((error as? ModelGeneratorErrorType)?.description() ?? "Unknown error.")")
            
            // Play error sound
            playSound(Service.errorSound)
        }
    }
    
    static func playSound(_ sound: NSSound?) {
        if !UserDefaults.standard.bool(forKey: "muteSound") {
            sound?.play()
        }
    }
}


// MARK: String manipulation
extension Service {
    
    // Create extensions while taking into account parent Model
    static func extensionBodies(fromSource source: String, generatorSettings:  ModelGeneratorSettings) throws -> [String]? {
        if let codes = try modelStrings(fromSourceCode: source) {
            var retVal = [String]()
            var outerModelPrefix = ""
            for (index, code) in codes.enumerated() {
                var codeToParse = code
                // first object is parent -> Save parent name
                if index == 0, let outerName = modelNameAndRange(fromSourceCode: codeToParse)?.0 {
                    outerModelPrefix = outerName + "."
                } else if let range = modelNameAndRange(fromSourceCode: codeToParse)?.1 {
                    
                    // For embedded Models, add Parent Model prefix before model name
                    codeToParse = ""
                    // TODO: When Swift 4 properly works: Replace the following code with String.insert(contentsOf: otherString, at: Index)
                    for (index, character) in code.enumerated() {
                        if index == range.lowerBound {
                            codeToParse.append(" \(outerModelPrefix)")
                        }
                        codeToParse.append(character)
                    }
                }
                // Add model string to return array
                let newCode = try ModelGenerator.modelCode(fromSourceCode: codeToParse, withSettings: generatorSettings)
                retVal.append(newCode)
            }
            return retVal
        }
        return nil
    }
    
    static func modelNameAndRange(fromSourceCode code: String) -> (String, NSRange)? {
        let range = NSMakeRange(0, code.characters.count)
        let match = modelNameRegex?.firstMatch(in: code, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
        
        // If we found model name
        if let match = match {
            return ((code as NSString).substring(with: match.range), match.range)
        }
        
        return nil
    }
    
    static func modelStrings(fromSourceCode code: String, regex: NSRegularExpression) throws -> [String]? {
        let range = NSMakeRange(0, code.characters.count)
        
        // Check for regex matches
        let matches = regex.numberOfMatches(in: code, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
        if matches == 1 {
            // In case just one match found, return this
            return [code]
            
        } else if matches > 1, let innerMatch = embeddedModelBodyRegex?.firstMatchInString(string: code) {
            
            // Extract embedded model
            let innerString = (code as NSString).substring(with: innerMatch.range)
            // remove embedded model
            let remainder = (code as NSString).replacingCharacters(in: innerMatch.range, with: "")
            
            do {
                // Call recursively with rest code and return along with first found value
                if let strings = try modelStrings(fromSourceCode: remainder) {
                    let retVal =  strings + [innerString]
                    return retVal
                }
            }
        }
        return nil
    }
    
    //Extracts models
    static func modelStrings(fromSourceCode code: String) throws -> [String]? {
        
        // Identify struct models
        if let matches = try modelStrings(fromSourceCode: code, regex: structRegex!) {
            return matches
        }
        
        //Identify final class models
        
        if let matches = try modelStrings(fromSourceCode: code, regex: finalClassRegex!) {
            return matches
        }
        else if code.contains("class") {
            throw ModelParserError.ClassShouldBeDeclaredAsFinal
        }
        
        // If no struct or class was found
        return nil
    }
    
    //Concatenates all the generated extensions
    static func extensionCode(fromBodies bodies: [String]) -> String {
        var bodiesMutating = bodies
        var retVal = ""
        if !bodies.isEmpty {
            retVal = bodiesMutating.removeFirst()
        }
        for body in bodiesMutating {
            retVal.append("\n\n\(body)")
        }
        
        return retVal
    }
}

// Regular expression used for parsing
extension Service {

    static var embeddedModelBodyRegex: NSRegularExpression? {
        do {
            let regex = try NSRegularExpression(
                pattern: "((?!^)(struct|final\\sclass)\\s\\w+\\s\\{[\\d\\S\\W]*?\\})",
                options: NSRegularExpression.Options(rawValue: 0))
            return regex
        } catch {
            print("Couldn't create model body regex.")
            return nil
        }
    }
    
    static var modelBodyRegex: NSRegularExpression? {
        do {
            let regex = try NSRegularExpression(
                pattern: "struct.*\\{(.*)\\}|class.*\\{(.*)\\}",
                options: [.dotMatchesLineSeparators])
            return regex
        } catch {
            print("Couldn't create model body regex.")
            return nil
        }
    }
    static var finalClassRegex: NSRegularExpression? {
        do {
            let regex = try NSRegularExpression(
                pattern: "final.*class(?=.*\\{)",
                options: NSRegularExpression.Options(rawValue: 0))
            return regex
        } catch {
            print("Couldn't create final class regex.")
            return nil
        }
    }
    
    static var structRegex: NSRegularExpression? {
        do {
            let regex = try NSRegularExpression(
                pattern: "struct(?=.*\\{)",
                options: NSRegularExpression.Options(rawValue: 0))
            return regex
        } catch {
            print("Couldn't create struct regex.")
            return nil
        }
    }
    
    static var modelNameRegex: NSRegularExpression? {
        do {
            let regex = try NSRegularExpression(
                pattern: "\\S+(?=\\s*\\:)|\\S+(?=\\s*\\{)",
                options: NSRegularExpression.Options(rawValue: 0))
            return regex
        } catch {
            print("Couldn't create model name regex.")
            return nil
        }
    }
}


