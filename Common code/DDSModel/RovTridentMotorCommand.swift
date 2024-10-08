/////
////  RovTridentMotorCommand.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

// Low-level motor commands. These get directly mapped to an equivalent Mavlink message and forwarded to each ESC
struct RovTridentMotorCommand: DDSKeyed {
    // Control Types
    enum EControlType: UInt32, Codable {
        case percentOfMax  = 0
        case radiansPerSec = 1
    }
    // Vehicle ID
    let id: String //@key

    // The type of control we are using
    let controlType: EControlType

    // Motor values
    let portCmd: Float // The value to send to the port motor
    let verticalCmd: Float // The value to send to the vertical motor
    let starboardCmd: Float // The value to send to the starboard motor
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::TridentMotorCommand" }
}

// Request motor configuration
struct TridentMotorConfigRequest: DDSUnkeyed {
    let id: String // Not used at present

    static var ddsTypeName: String { "orov::msg::control::TridentMotorConfigRequest" }
}

struct TridentMotorConfig: DDSKeyed {
    // MCU ID
    let id: String //@key

    // Motor values
    let minSpeed: Float // Minimum speed error
    let maxSpeed: Float // Maximum speed error
    let timeout: UInt32   // Timeout in milliseconds
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::control::TridentMotorConfig" }
}
