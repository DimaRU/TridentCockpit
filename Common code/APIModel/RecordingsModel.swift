/////
////  RecordingsModel.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation

struct RecordingsResponce: Codable {
    let recordings: [Recording]
}

struct Recording: Codable {
    struct Segment: Codable {
        let size: Int
        let uri: String
    }

    let sessionId: String
    let uri: String
    let previewUri: String
    let startTimestamp: Date
    let segments: [Segment]
}
