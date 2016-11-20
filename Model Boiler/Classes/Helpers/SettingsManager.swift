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
    static func isSettingEnabled(_ setting: Setting) -> Bool {
        return UserDefaults.standard.bool(forKey: setting.rawValue)
    }

    static func setSetting(_ setting: Setting, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: setting.rawValue)
    }
}
