/////
////  Preferences.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

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

    @UserPreference("AuxCameraPlayerViewCPV")
    static var auxCameraPlayerViewCPV: CGFloat?

    @UserPreference("AuxCameraPlayerViewCPH")
    static var auxCameraPlayerViewCPH: CGFloat?

    @UserPreferenceWithDefault("TridentStabilize", defaultValue: true)
    static var tridentStabilize: Bool
    
    @UserPreferenceWithDefault("VideoOverlayMode", defaultValue: true)
    static var videoOverlayMode: Bool
    
    @UserPreferenceWithDefault("VideoSizingFill", defaultValue: true)
    static var videoSizingFill: Bool

}
