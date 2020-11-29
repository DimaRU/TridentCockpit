/////
////  RovBeacon.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import FastRTPSSwift

struct ResinInfo: Codable {
    let deviceUuid: String         //@key

    let deviceType: String         // e.g., "Raspberry Pi 3"
    let appRelease: String         // Git commit hash
    let appName: String            // e.g., "rovImageResinDev"
    let supervisorVersion: String  // e.g., "6.1.3"
    let hostOsVersion: String      // e.g., "Resin OS 2.3.0+rev1 (prod)"
}

struct RovBeacon: DDSKeyed {
    let uuid: String                //@key
    let productType: String         //@key
    let systemStatus: String        // General system status info, potentially useful for debugging and high level system views

    let resinInfo: ResinInfo

    var key: Data { (uuid + productType).data(using: .utf8)! }
    static var ddsTypeName: String { "orov::msg::system::ROVBeacon" }
}
