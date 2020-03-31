/////
////  RovGPS.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovGPS: DDSUnkeyed {
    let online: UInt8
    let utc: Double
    let latitude: Double
    let NS: UInt8
    let longitude: Double
    let EW: UInt8
    let speed: Double
    let course: Double

    static var ddsTypeName: String { "orov::msg::sensor::GPS" }
}
