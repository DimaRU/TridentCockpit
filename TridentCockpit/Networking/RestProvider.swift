/////
////  RestProvider.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import PromiseKit

class RestProvider {
    typealias Response = Decodable
    typealias ErrorBlock = (Error) -> Void
    typealias RequestFuture = (target: MultiTarget, resolve: (Response) -> Void, reject: ErrorBlock)
    
    static let manager: Session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 2
        configuration.timeoutIntervalForResource = 5
        return Session(configuration: configuration)
    }()
    
    fileprivate static let restProvider = MoyaProvider<MultiTarget>(session: manager)
    
    // MARK: - Public
    class func request(_ target: MultiTarget) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        RestProvider.sendRequest((target,
                     resolve: { _ in seal.fulfill(Void()) },
                     reject: seal.reject))
        return promise
    }

    class func request<T: Decodable>(_ target: MultiTarget) -> Promise<T> {
        let (promise, seal) = Promise<T>.pending()
        RestProvider.sendRequest((target,
                     resolve: { self.parseData(data: $0 as! Data, seal: seal, target: target) },
                     reject: seal.reject))
        return promise
    }
    
    private class func sendRequest(_ request: RequestFuture) {
        #if DEBUG
        print("Request:", request.target)
        #endif
        restProvider.request(request.target) { (result) in
            RestProvider.handleRequest(request: request, result: result)
        }
    }
}


extension RestProvider {
    private class func handleRequest(request: RequestFuture, result: Swift.Result<Moya.Response, MoyaError>) {
        switch result {
        case .success(let moyaResponse):
            #if DEBUG
            print(moyaResponse.request?.url?.absoluteString ?? "", moyaResponse.statusCode)
            #endif
            switch moyaResponse.statusCode {
            case 200...299, 300...399:
                request.resolve(moyaResponse.data)
            case 404:
                let error = NetworkError.notFound
                request.reject(error)
            default:
                let statusCode = moyaResponse.statusCode
                let error = NetworkError.serverError(code: statusCode)
                request.reject(error)
            }
        case .failure(let error):
            request.reject(NetworkError.unaviable(message: error.localizedDescription))
            break
        }
    }
    
    
    private class func parseData<T: Decodable>(data: Data, seal: Resolver<T>, target: MultiTarget) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let object = try decoder.decode(T.self, from: data)
            seal.fulfill(object)
        } catch {
            #if DEBUG
            print(error)
            #endif
            let message = error.localizedDescription
            seal.reject(NetworkError.responceSyntaxError(message: message))
        }
    }
}
