//
//  SettingsManager.swift
//  Model Boiler
//
//  Created by Dominik Hádl on 26/01/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

enum Setting: String {
    case AppWasOpened          = "AppWasOpened"
    case SoundEnabled          = "SoundEnabled"
    case NoCamelCaseConversion = "NoCamelCaseConversion"
    case UseNativeDictionaries = "UseNativeDictionaries"
    case OnlyCreateInitializer = "OnlyCreateInitializer"
}

struct SettingsManager {
    static func isSettingEnabled(setting: Setting) -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(setting.rawValue)
    }

    static func setSetting(setting: Setting, enabled: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(enabled, forKey: setting.rawValue)
    }
}