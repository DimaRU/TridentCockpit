/////
////  DeviceState.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct DeviceState: Codable, Equatable {
    let apiPort: Int
    let commit: String
    let status: String
    let updateFailed: Bool
    let downloadProgress: String?
    let updateDownloaded: Bool
    let updatePending: Bool
    let osVariant: String
    let osVersion: String
    let ipAddress: String
    let supervisorVersion: String
}
