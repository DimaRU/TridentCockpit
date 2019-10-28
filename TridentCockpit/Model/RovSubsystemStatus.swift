/////
////  RovSubsystemStatus.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovSubsystemStatus: DDSKeyed {
    
    // Trident subsystem IDs
    enum SubsystemID: String, Codable {
        // Comm Buses
        case samdUartMain     = "samd_uart_main"
        case samdI2cMain      = "samd_i2c_main"
        
        // Actuators
        case forwardLights    = "fwd_light"
        case portMotor        = "port_motor"
        case vertMotor        = "vert_motor"
        case starMotor        = "star_motor"
        case statusLights     = "status_light"
        
        // Sensors
        case fuelGauge        = "fuel_gauge"
        case imu              = "main_imu"
        case depth            = "depth"
        case barometer        = "barometer"
        
        // Processes
        case batteryFlasher   = "batt_flasher"
    }
    
    enum ESubsystemType: Int32, Codable {
        case unknown         = 0
        case sensor          = 1
        case actuator        = 2
        case power           = 3
        case communication   = 4
        case process         = 5
    }
    
    enum ESubsystemPostResult: Int32, Codable {
        case unknown = 0
        case waiting = 1
        case failure = 2
        case success = 3
    }
    
    enum ESubsystemState: Int32, Codable {
        case unknown         = 0
        case initialized     = 1
        case posting         = 2
        case active          = 3
        case standby         = 4
        case recovery        = 5
        case disabled        = 6
    }
    
    let subsystemId: SubsystemID            //@key
    let type: ESubsystemType
    
    let postResult: ESubsystemPostResult    // Final result of the POST process for the subsystem, if it has one.
    let state: ESubsystemState              // High-level view of a subsystem's operational state
    let substate: UInt8                     // Subsystem-specific substate. Combined with state, generally describes a hierarchical state machine
    
    var key: Data { subsystemId.rawValue.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::SubsystemStatus" }
}
