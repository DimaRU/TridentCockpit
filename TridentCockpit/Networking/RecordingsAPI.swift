/////
////  RecordingsAPI.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import Moya

enum RecordingsAPI {
    case recordings
    case recording(id: String)
    case preview(id: String)
    case video(id: String)
    case delete(id: String)
}

extension RecordingsAPI: TargetType {
    var baseURL: URL {
        return URL(string: "http://\(FastRTPS.remoteAddress):3000")!
    }
    
    var path: String {
        switch self {
        case .recordings:
            return "/recordings"
        case .recording(let id):
            return "/recordings/" + id
        case .preview(let id):
            return "/recordings/" + id
        case .video(let id):
            return "/recordings/" + id
        case .delete(let id):
            return "/recordings/" + id
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .recordings,
             .recording,
             .preview,
             .video:
            return .get
        case .delete:
            return .delete
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .recordings:
            return .requestPlain
        case .recording:
            return .requestPlain
        case .preview:
            return .requestPlain
        case .video:
            return .requestPlain
        case .delete:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    
}
