/////
////  Preferences.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

@propertyWrapper
struct UserPreferenceWithDefault<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct UserPreference<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T? {
        get {
            return UserDefaults.standard.object(forKey: key) as? T
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct Preference {
    @UserPreference("CameraControlViewCPV")
    static var cameraControlViewCPV: CGFloat?

    @UserPreference("CameraControlViewCPH")
    static var cameraControlViewCPH: CGFloat?

    @UserPreference("RovModelViewCPV")
    static var rovModelViewCPV: CGFloat?

    @UserPreference("RovModelViewCPH")
    static var rovModelViewCPH: CGFloat?

    @UserPreferenceWithDefault("TridentStabilize", defaultValue: true)
    static var tridentStabilize: Bool
    
    @UserPreferenceWithDefault("VideoOverlayMode", defaultValue: true)
    static var videoOverlayMode: Bool
}
