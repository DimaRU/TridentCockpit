/////
////  RovAttitude.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovAttitude: DDSKeyed {
    let header: RovHeader
    let orientation: RovQuaternion
    let angularVelocity: RovVector3
    
    let id: String

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::Attitude" }
}
