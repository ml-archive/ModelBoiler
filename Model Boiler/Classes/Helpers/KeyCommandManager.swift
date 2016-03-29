//
//  KeyCommandManager.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 27/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Cocoa

struct KeyCommandManager {

    static let settingsKey = "KeyCommandManager"

    static func setDefaultKeyCommand() {
        let key  = "§"
        let mask = NSEventModifierFlags.CommandKeyMask

        do {
            try KeyCommandManager.updateKeyCommand(key, modifierMask: mask)
        } catch {

        }
    }

    // MARK: - Key Command -

    static func currentKeyCommand() -> (command: String, modifierMask: NSEventModifierFlags)? {
        if let keyCommandString = NSUserDefaults.standardUserDefaults().stringForKey(settingsKey) {
            return keyCommandForString(keyCommandString)
        }

        return nil
    }

    static func updateKeyCommand(command: String, modifierMask: NSEventModifierFlags) throws {
        let bundle = NSBundle.mainBundle()

        guard let appServices = bundle.infoDictionary?["NSServices"]?.firstItem as? [String: AnyObject],
            bundleIdentifier = bundle.bundleIdentifier,
            serviceName = appServices["NSMenuItem"]?["default"] as? String,
            methodName = appServices["NSMessage"] as? String else {

                throw NSError(domain: "com.nodes.Model-Boiler", code: 1000, userInfo: [NSLocalizedDescriptionKey : "Can't get information about app services."])
        }

        let serviceHelperName = "pbs"
        let serviceStatusName = "\(bundleIdentifier) - \(serviceName) - \(methodName)"
        let serviceStatusRoot = "NSServicesStatus"

        var services: [String: AnyObject] = (CFPreferencesCopyAppValue(serviceStatusRoot, serviceHelperName) as? [String: AnyObject] ?? [:])

        let keyCommand = stringForKeyCommand(command, modifierMask: modifierMask)

        NSUpdateDynamicServices()

        let serviceStatus: [String: AnyObject] = [
            "enabled_context_menu" : true,
            "enabled_services_menu" : true,
            "key_equivalent" : keyCommand]

        services[serviceStatusName] = serviceStatus

        CFPreferencesSetAppValue(serviceStatusRoot, services, serviceHelperName)

        let success = CFPreferencesAppSynchronize(serviceHelperName)

        if success {
            NSUpdateDynamicServices()
            system("/System/Library/CoreServices/pbs -flush");
            NSUserDefaults.standardUserDefaults().setObject(keyCommand, forKey: settingsKey)
        } else {
            throw NSError(domain: bundleIdentifier, code: 1000, userInfo: [NSLocalizedDescriptionKey : "Can't save key command for service."])
        }
    }

    // MARK: - Helpers -

    static func stringForKeyCommand(command: String, modifierMask: NSEventModifierFlags) -> String {
        var key = ""

        if modifierMask.contains(.CommandKeyMask) { key += "@" }
        if modifierMask.contains(.AlternateKeyMask) { key += "~" }
        if modifierMask.contains(.ShiftKeyMask) { key += "$" }

        return key + (command == "$" ? "\\$" : command)
    }


    static func keyCommandForString(string: String) -> (command: String, modifierMask: NSEventModifierFlags) {
        var returnValue = (command: "", modifierMask: NSEventModifierFlags(rawValue: 0))
        if string.characters.count == 0 { return returnValue }

        switch string.characters.first! {
        case "@": returnValue.modifierMask = .CommandKeyMask
        case "~": returnValue.modifierMask = .AlternateKeyMask
        case "$": returnValue.modifierMask = .ShiftKeyMask
        default: break
        }

        let command = string.substringFromIndex(string.startIndex.advancedBy(1))

        returnValue.command = (command == "\\$" ? "$" : command)

        return returnValue
    }
}