/////
////  RovIMUCalibration.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct RovIMUCalibration: DDSKeyed {
    enum Calibration: UInt8, Codable {
        case uncalibrated    = 0
        case poor            = 1
        case fair            = 2
        case excellent       = 3
    }
    // Pertains mainly to the BNO055 with its concept of 0-3 calibration readiness values
    let id: String  //@key

    let accel: Calibration    // Calibration state of the accelerometer
    let gyro: Calibration     // Calibration state of the gyro
    let mag: Calibration      // Calibration state of the mag
    let system: Calibration   // Calibration state of the system
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::IMUCalibration" }
}
