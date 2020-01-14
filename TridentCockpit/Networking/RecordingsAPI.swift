/////
////  RecordingsAPI.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import Alamofire

final class RecordingsAPI {
    static var baseURL: String {
        return "http://\(FastRTPS.remoteAddress):3000/recordings/"
    }
    
    class func requestRecordings(completion: @escaping (Result<RecordingsResponce, AFError>) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Date.iso8601FullFormatter)

        AF.request(baseURL, method: .get)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: RecordingsResponce.self, decoder: decoder) {
                completion($0.result)
        }
    }

    class func deleteRecording(sessionId: String, completion: @escaping (AFError?) -> Void) {
        DispatchQueue.main.async {
            completion(nil)
        }
//        AF.request(baseURL + sessionId, method: .delete)
//            .validate(statusCode: 200..<300)
//            .response(queue: DispatchQueue.main) { responce in
//                switch responce.result {
//                case .success(_):
//                    completion(nil)
//                case .failure(let error):
//                    completion(error)
//                }
//        }
    }
    
    class func downloadRecording(recording: Recording,
                           fileURL: URL,
                           progress: @escaping (Progress) -> Void,
                           completion: @escaping (AFError?) -> Void) -> DownloadRequest {

        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadRequest = AF.download(baseURL + recording.segments[0].uri, to: destination)
            .downloadProgress(queue: DispatchQueue.main, closure: progress)
            .validate(statusCode: 200..<300)
            .response(queue: DispatchQueue.main) { responce in
                switch responce.result {
                case .success(_):
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
        }
        return downloadRequest
    }
    
    class func videoURL(recording: Recording) -> URL {
        return URL(string: baseURL + recording.segments[0].uri)!
    }
    
    class func previewURL(recording: Recording) -> URL {
        return URL(string: baseURL + recording.previewUri)!
    }

}
