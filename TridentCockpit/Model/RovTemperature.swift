/////
////  RovTemperature.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovTemperature: DDSKeyed {
    struct Temperature_: Codable{
        let header: RovHeader
        let temperature: Double
        let variance: Double
    }
    
    let temperature: Temperature_
    let id: String
    
    var key: Data { id.data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::sensor::Temperature" }

}
