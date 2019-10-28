/////
////  RovCommon.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge

struct RovTime: Codable {
    let sec: Int32
    let nanosec: UInt32
}

struct RovHeader: Codable {
    let stamp: RovTime
    let frameId: String
}
