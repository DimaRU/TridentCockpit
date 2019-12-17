/////
////  ResinAPI.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import Moya

enum ResinAPI {
    case version
    case imageVersion
    case latestRelease
    case ping
    case deviceState
    case appInfo
    case checkUpdate
    case reboot
}

extension ResinAPI: TargetType {
    var baseURL: URL {
        return URL(string: "http://\(FastRTPS.remoteAddress):3091")!
    }
    
    var path: String {
        switch self {
        case .version       : return "/version"
        case .imageVersion  : return "/imageVersion"
        case .latestRelease : return "/latestRelease"
        case .ping          : return "/supervisor/ping"
        case .deviceState   : return "/supervisor/deviceState"
        case .appInfo       : return "/supervisor/appInfo"
        case .checkUpdate   : return "/supervisor/checkUpdate"
        case .reboot        : return "/supervisor/reboot"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    
}
