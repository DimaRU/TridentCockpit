/////
////  RovCameraObjectTrack.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct RovCameraObjectTrack: DDSKeyed {
    
    enum RovTrackingStatus: UInt8, Codable {
        case locked     = 0
        case unlocked   = 1
        case locking    = 2
        case count      = 3
    }

    // ID of the system reporting the bounding box
    let id: String               //@key
    let cameraTopic: String      //@key
    
    let tracking: RovTrackingStatus
    let min_pt: RovPoint    //the min value x,y coordinates of the bounding box
    let max_pt: RovPoint    //the max value x,y coordinates of the bounding box

    var key: Data { (id + cameraTopic).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::image::CameraObjectTrack" }
}
