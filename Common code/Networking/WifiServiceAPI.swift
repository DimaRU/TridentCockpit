/////
////  WifiServiceAPI.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import Moya

enum WiFiServiceAPI {
    case version
    case ssids
    case connection
    case internetAccess
    case connect(ssid: String, passphrase: String)
    case disconnect
    case clear
    case scan
    case setupAP(ssid: String, passphrase: String)
}

extension WiFiServiceAPI: TargetType {
    var baseURL: URL {
        return URL(string: "http://\(FastRTPS.remoteAddress):3090")!
    }
    
    var path: String {
        switch self {
        case .version        : return "/version"
        case .ssids          : return "/ssids"
        case .connection     : return "/connection"
        case .internetAccess : return "/internetAccess"
        case .connect        : return "/connect"
        case .disconnect     : return "/disconnect"
        case .clear          : return "/clear"
        case .scan           : return "/scan"
        case .setupAP        : return "/setup-ap"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .version,
             .ssids,
             .connection,
             .internetAccess:
            return .get
        case .connect,
             .disconnect,
             .clear,
             .scan,
             .setupAP:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .connect(let ssid, let passphrase):
            let params: [String: Any] = ["ssid" : ssid, "passphrase" : passphrase]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .setupAP(let ssid, let passphrase):
            let params: [String: Any] = ["ssid" : ssid, "passphrase" : passphrase]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        default:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .connect,
             .setupAP:
            return ["Content-Type": "application/json"]
        default:
            return nil
        }
    }
}
