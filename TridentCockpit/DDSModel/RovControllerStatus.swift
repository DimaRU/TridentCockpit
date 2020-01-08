/////
////  RovControllerStatus.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovControllerStatus: DDSKeyed {
    
    // Trident controller constants
    enum ControllerID: String, Codable {
        // Pitch-related controllers
        case verticalThruster    = "vertical_thruster"      // Controllers that interact with vertical thrust. Pitch
        case transectPitchHold   = "transect_pitch_hold"
        case depthHold           = "depth_hold"
        
        // Yaw-related controllers
        case headingHold         = "heading_hold"
        case yawPosHold          = "yaw_pos_hold"
        case yawRateRampdown     = "yaw_rate_rampdown"
        
        // The entire trident control system
        case trident             = "trident_stabilize"
        
        // The depth safety check
        case depthSafety         = "depth_safety"
    }
    
    // State of the controller
    enum ControllerState: Int32, Codable {
        case enabled     = 0
        case disabled    = 1
    }
    
    let vehicleId: String           //@key
    let controllerId: ControllerID  //@key
    
    let state: ControllerState      // State of the controller, either disabled or enabled

    var key: Data { (vehicleId + controllerId.rawValue).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::ControllerStatus" }
}
