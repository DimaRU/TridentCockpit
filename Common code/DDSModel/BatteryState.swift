/////
////  BatteryState.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct BatteryState: Codable {
    enum PowerSupplyStatus: UInt8, Codable {
        case unknown      = 0
        case charging     = 1
        case discharging  = 2
        case not_charging = 3
        case full         = 4
    }
    enum PowerSupplyHealth: UInt8, Codable {
        case unknown             = 0
        case good                = 1
        case overheat            = 2
        case dead                = 3
        case overvoltage         = 4
        case unspecFailure       = 5
        case cold                = 6
        case watchdogTimerExpire = 7
        case safetyTimerExpire   = 8
    }
    enum PowerSupplyTechnology: UInt8, Codable {
        case unknown = 0
        case nimh    = 1
        case lion    = 2
        case lipo    = 3
        case life    = 4
        case nicd    = 5
        case limn    = 6
    }
    
    let header: RovHeader

    let voltage: Float                       // Volts
    let current: Float                       // Amps (negative when discharging)
    let charge: Float                        // Current charge in Ah
    let capacity: Float                      // Capacity in Ah (last known)
    let design_capacity: Float               // Capacity in Ah (at design)
    let percentage: Float                    // Charge percentage 0.0 to 1.0

    let powerSupplyStatus: PowerSupplyStatus
    let powerSupplyHealth: PowerSupplyHealth
    let powerSupplyTechnology: PowerSupplyTechnology

    let present: Bool
    let cellVoltage: [Float]       // Volts

    let location: String
    let serial_number: String
}
