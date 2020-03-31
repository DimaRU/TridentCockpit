/////
////  RovAttitudeEuler.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovAttitudeEuler: DDSKeyed {
    struct Axis: Codable {
        let roll: Double
        let pitch: Double
        let yaw: Double
    }
    
    struct AxisRate: Codable {
        let rollRate: Double
        let pitchRate: Double
        let yawRate: Double
    }
    let header: RovHeader
    let orientationEuler: Axis      // degrees roll pitch yaw
    let angularVelocity: AxisRate
    let heading: Double             // compass degrees
    let id: String

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::AttitudeEuler" }
}
