/////
////  GoproStatus.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct GoproStatus: Codable {
    enum CameraMode: UInt8, Codable {
        case video = 0
        case photo = 1
        case burst = 2
        case timelapse = 3
    }

    let data: Data
    
    var mode: CameraMode {
        CameraMode(rawValue: data[1]) ?? .video
    }
    var videoProgress: (UInt8,UInt8,UInt8) {
        ((data[13] / 60),
         (data[13] % 60),
         data[14])
    }
    var photoRemaining: UInt {
        UInt(data[21]) << 8 + UInt(data[22])
    }
    var photoCount: UInt {
        UInt(data[23]) << 8 + UInt(data[24])
    }
    var videoRemaining: UInt32 {
        let min = UInt32(data[25]) << 8 + UInt32(data[26])
        return min
    }
    var videoCount: UInt {
        UInt(data[27]) << 8 + UInt(data[28])
    }
    var recording: Bool {
        data[29] == 1
    }
    var battery: String {
        switch data[19] {
        case 0: return "10%"
        case 1: return "40%"
        case 2: return "70%"
        case 3: return "100%"
        case 4: return "chg"
        default: return "??"
        }
    }
}
