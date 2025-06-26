//
//  UserDefaultsManager.swift
//  Utility
//
//  Created by Den on 4/29/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    private(set) var container: UserDefaults = .standard
    
    public var wrappedValue: Value {
        get {
            return self.container.object(forKey: self.key) as? Value ?? self.defaultValue
        }
        set {
            print("UserDefault set '\(self.key) to \(newValue)")
            self.container.set(newValue, forKey: self.key)
        }
    }
}

public struct UserDefaultManager {
    
    private enum UserDefaultsManagerKeys: String {
        case thema
        case font
        case bright
        case start
        case timerRunning
        case engagedTime
        case stopCount
        case hasSeenFirstPageOnboarding
    }

    @UserDefault(key: UserDefaultsManagerKeys.thema.rawValue, defaultValue: 0)
    public static var thema: Int
    
    @UserDefault(key: UserDefaultsManagerKeys.font.rawValue, defaultValue: 0)
    public static var font: Int
    
    @UserDefault(key: UserDefaultsManagerKeys.bright.rawValue, defaultValue: 0)
    public static var bright: CGFloat
    
    @UserDefault(key: UserDefaultsManagerKeys.start.rawValue, defaultValue: false)
    public static var start: Bool
    
    @UserDefault(key: UserDefaultsManagerKeys.engagedTime.rawValue, defaultValue: 900)
    public static var engagedTime: Int
    
    @UserDefault(key: UserDefaultsManagerKeys.timerRunning.rawValue, defaultValue: false)
    public static var timerRunning: Bool
    
    @UserDefault(key: UserDefaultsManagerKeys.stopCount.rawValue, defaultValue: 3)
    public static var stopCount: Int
    
    @UserDefault(key: UserDefaultsManagerKeys.hasSeenFirstPageOnboarding.rawValue, defaultValue: false)
    public static var hasSeenFirstPageOnboarding: Bool
}

