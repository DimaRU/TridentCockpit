/////
////  ConnectionInfo.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct ConnectionInfo: Codable, Equatable {
    let kind: String
    let id: String
    let uuid: String
    let ssid: String
    let mode: String
    let state: String
}
