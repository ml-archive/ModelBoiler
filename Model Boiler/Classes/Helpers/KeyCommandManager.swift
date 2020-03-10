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
        let mask = NSEvent.ModifierFlags.command

        do {
            try KeyCommandManager.updateKeyCommand(key, modifierMask: mask)
        } catch {

        }
    }

    // MARK: - Key Command -

    static func currentKeyCommand() -> (command: String, modifierMask: NSEvent.ModifierFlags)? {
        if let keyCommandString = UserDefaults.standard.string(forKey: settingsKey) {
            return keyCommandForString(keyCommandString)
        }

        return nil
    }

    static func updateKeyCommand(_ command: String, modifierMask: NSEvent.ModifierFlags) throws {
        let bundle = Bundle.main

        guard let appServices = (bundle.infoDictionary?["NSServices"] as AnyObject).firstObject as? [String: AnyObject],
            let bundleIdentifier = bundle.bundleIdentifier,
            let serviceName = appServices["NSMenuItem"]?["default"] as? String,
            let methodName = appServices["NSMessage"] as? String else {

                throw NSError(domain: "com.nodes.Model-Boiler", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Can't get information about app services."])
        }

        let serviceHelperName = "pbs"
        let serviceStatusName = "\(bundleIdentifier) - \(serviceName) - \(methodName)"
        let serviceStatusRoot = "NSServicesStatus"

        var services: [String: AnyObject] = (CFPreferencesCopyAppValue(serviceStatusRoot as CFString, serviceHelperName as CFString) as? [String: AnyObject] ?? [:])

        let keyCommand = stringForKeyCommand(command, modifierMask: modifierMask)

        NSUpdateDynamicServices()

        let serviceStatus: [String: AnyObject] = [
            "enabled_context_menu": true as AnyObject,
            "enabled_services_menu": true as AnyObject,
            "key_equivalent": keyCommand as AnyObject]

        services[serviceStatusName] = serviceStatus as AnyObject?

        CFPreferencesSetAppValue(serviceStatusRoot as CFString, services as CFPropertyList?, serviceHelperName as CFString)

        let success = CFPreferencesAppSynchronize(serviceHelperName as CFString)

        if success {
            NSUpdateDynamicServices()

            let task = Process()
            task.launchPath = "/System/Library/CoreServices/pbs"
            task.arguments = ["-flush"]
            task.launch()

            UserDefaults.standard.set(keyCommand, forKey: settingsKey)
        } else {
            throw NSError(domain: bundleIdentifier, code: 1000, userInfo: [NSLocalizedDescriptionKey: "Can't save key command for service."])
        }
    }

    // MARK: - Helpers -

    static func stringForKeyCommand(_ command: String, modifierMask: NSEvent.ModifierFlags) -> String {
        var key = ""

        if modifierMask.contains(.command) { key += "@" }
        if modifierMask.contains(.option) { key += "~" }
        if modifierMask.contains(.shift) { key += "$" }

        return key + (command == "$" ? "\\$" : command)
    }

    static func keyCommandForString(_ string: String) -> (command: String, modifierMask: NSEvent.ModifierFlags) {
        var returnValue = (command: "", modifierMask: NSEvent.ModifierFlags(rawValue: 0))
        if string.isEmpty { return returnValue }

        switch string.first! {
        case "@": returnValue.modifierMask = .command
        case "~": returnValue.modifierMask = .option
        case "$": returnValue.modifierMask = .shift
        default: break
        }

        let command = string[string.index(string.startIndex, offsetBy: 1)...]

        returnValue.command = (command == "\\$" ? "$" : String(command))

        return returnValue
    }
}
