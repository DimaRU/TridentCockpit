/////
////  RovLightPower.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovLightPower: DDSKeyed
{
    // Light ID: forward, accesory_id, etc
    let id: String       //@key
    let power: Float      // Percent, 0.0 to 1.0
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::device::LightPower" }
}


