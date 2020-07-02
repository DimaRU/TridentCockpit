/////
////  Preferences.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

struct Preference {
    @UserPreference("CameraControlViewCPV")
    static var cameraControlViewCPV: CGFloat?

    @UserPreference("CameraControlViewCPH")
    static var cameraControlViewCPH: CGFloat?

    @UserPreference("RovModelViewCPV")
    static var rovModelViewCPV: CGFloat?

    @UserPreference("RovModelViewCPH")
    static var rovModelViewCPH: CGFloat?
    
    @UserPreference("AuxCameraControlViewCPV")
    static var auxCameraControlViewCPV: CGFloat?

    @UserPreference("AuxCameraControlViewCPH")
    static var auxCameraControlViewCPH: CGFloat?

    @UserPreferenceWithDefault("TridentStabilize", defaultValue: true)
    static var tridentStabilize: Bool
    
    @UserPreferenceWithDefault("VideoOverlayMode", defaultValue: true)
    static var videoOverlayMode: Bool
}
