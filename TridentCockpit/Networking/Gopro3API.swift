/////
////  Gopro3API.swift
///   Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import PromiseKit

enum Gopro3API {
    case getPassword
    case status
    case power(on: Bool)
    case preview(on: Bool)
    case cameraModel
    case shot(on: Bool)
    
    static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration)
    }()

    static var cameraPassword: String?
    static var isConnected: Bool {
        Gopro3API.cameraPassword != nil
    }
    static let basePort = Int(Bundle.main.infoDictionary!["BasePort"]! as! String)!
    static var liveStreamURL: URL {
        get {
            let streamingPort = Gopro3API.basePort + 1
            let address = FastRTPS.remoteAddress
            return URL(string: "http://\(address):\(streamingPort)/live/amba.m3u8")!
        }
    }

    static func getString(from data: Data) -> [String] {
        guard data.count >= 2 else { return [] }
        var strings: [String] = []
        var ptr = data.startIndex
        while ptr < data.endIndex {
            let lenght = Int(UInt(data[ptr]))
            ptr = ptr.advanced(by: 1)
            let range = ptr..<ptr.advanced(by: lenght)
            strings.append(String(data: data[range], encoding: .ascii) ?? "")
            ptr = ptr.advanced(by: lenght)
        }
        return strings
    }
}

extension Gopro3API {
    var path: String {
        switch self {
        case .getPassword : return "/bacpac/sd"
        case .status      : return "/camera/sx"
        case .power       : return "/bacpac/PW"
        case .preview     : return "/camera/PV"
        case .cameraModel : return "/camera/cv"
        case .shot        : return "/bacpac/SH"
        }
    }

    private var queryItems: [URLQueryItem]? {
        switch self {
        case .getPassword:
            return nil
        case .cameraModel:
            return nil
        case .status:
            return [URLQueryItem(name: "t", value: Gopro3API.cameraPassword!)]
        case .power(let on):
            return [
                URLQueryItem(name: "t", value: Gopro3API.cameraPassword!),
                URLQueryItem(name: "p", value: on ? "\u{01}" : "\u{00}")
            ]
        case .preview(let on):
            return [
                URLQueryItem(name: "t", value: Gopro3API.cameraPassword!),
                URLQueryItem(name: "p", value: on ? "\u{02}" : "\u{00}")
            ]
        case .shot(let on):
            return [
                URLQueryItem(name: "t", value: Gopro3API.cameraPassword!),
                URLQueryItem(name: "p", value: on ? "\u{01}" : "\u{00}")
            ]
        }
    }
    
    private func createRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = FastRTPS.remoteAddress
        urlComponents.path = path
        urlComponents.port = Gopro3API.basePort
        urlComponents.queryItems = queryItems
        
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [:]
        return request
    }
    
    func sendRequest(success: @escaping (Data) -> Void, failure: @escaping (Error) -> Void) {
        if Gopro3API.cameraPassword == nil {
            if case .getPassword = self {}
            else {
                failure(NetworkError.unprovisioned)
                return
            }
        }
        let urlRequest = createRequest()
        
        let dataTask = Gopro3API.sharedSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                failure(NetworkError.unaviable(message: error!.localizedDescription))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                switch statusCode {
                case 200...299:
                    break
                case 404:
                    failure(NetworkError.notFound)
                case 410:
                    failure(NetworkError.gone)
                default:
                    failure(NetworkError.serverError(code: statusCode))
                }
            }
            success(data ?? Data())
        }
        dataTask.resume()
    }
    
    static func request(_ target: Gopro3API) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        target.sendRequest(
            success: { _ in seal.fulfill(Void()) },
            failure: { seal.reject($0)} )
        return promise
    }

    static func requestData(_ target: Gopro3API) -> Promise<Data> {
        let (promise, seal) = Promise<Data>.pending()
        target.sendRequest(
            success: { seal.fulfill($0) },
            failure: { seal.reject($0) } )
        return promise
    }
    
    static func attempt<T>(retryCount: Int = 3, delay: DispatchTimeInterval = .seconds(1), _ body: @escaping () -> Promise<T>) -> Promise<T> {
        var attempts = 0
        func attempt() -> Promise<T> {
            attempts += 1
            return body().recover { error -> Promise<T> in
                guard case NetworkError.gone = error else { throw error }
                guard attempts < retryCount else { throw error }
                return after(delay).then(on: nil, attempt)
            }
        }
        return attempt()
    }
    
}

