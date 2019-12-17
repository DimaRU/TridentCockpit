/////
////  AppInfo.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct AppInfo: Codable {
    let containerId: String
    let imageId: String
    let appId: String
    let commit: String
    let env: [String: String]
}
