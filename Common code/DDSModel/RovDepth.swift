/////
////  RovDepth.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct RovDepth: DDSKeyed {
    let pressure: FluidPressure
    let id: String      // @key
    let depth: Float    // Unit: meters
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::Depth" }
}


struct RovDepthConfig: DDSKeyed {
    enum WaterType: UInt8, Codable {
        case fresh = 0
        case brackish = 1
        case salt = 2
        case count = 3
    }

    let id: String                //@key
    let waterType: WaterType      // See Above. Determines which constant to use for depth calculations
    let user_offset_enabled: Bool
    let zero_offset: Float        // Determined by entity at startup. Used as the zero point to offset depth calculated from sensor outputs. Unit: meters
    let zero_offset_user: Float   // Zero offset provided by user to override the initially determined value. Unit: meters

    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::DepthConfig" }
}

