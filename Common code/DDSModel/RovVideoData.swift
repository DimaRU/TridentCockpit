/////
////  RovVideoData.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSBridge


//const unsigned long VIDEO_DATA_MAX_SIZE = 1000 * 1024;           // 1MB
//const unsigned long IMAGE_DATA_MAX_SIZE = 12 * 1024 * 1024;     // 12MB

struct RovVideoData: DDSUnkeyed {
    let timestamp: UInt64
    let frame_id: UInt64
    let data: Data

    static var ddsTypeName: String { "orov::msg::image::VideoData" }
}
