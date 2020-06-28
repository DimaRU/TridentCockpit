/////
////  RecordingsAPI.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation
import UIKit

protocol RecordingsAPIProtocol: class {
    func progress(sessionId: String, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func downloadEnd(sessionId: String)
    func downloadError(sessionId: String, error: Error)
}

final class RecordingsAPI: NSObject {
    static let pilotPath = "Pilot"
    static let downloadsPath = "Trident-1080p"
    
    static var shared = RecordingsAPI()
    var backgroundSessionCompletionHandler: (() -> Void)?

    private weak var delegate: RecordingsAPIProtocol?
    private var baseURL: String?
    
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "in.TdidentCockpit.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = false
        config.waitsForConnectivity = false
        config.httpMaximumConnectionsPerHost = 1
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()

    #if targetEnvironment(macCatalyst)
    static var moviesURL: URL = {
        var url = FileManager.default.urls(for: .moviesDirectory, in: .allDomainsMask).first!
        let lastcomponent = url.lastPathComponent
        for _ in 1...5 {
            url.deleteLastPathComponent()
        }
        url.appendPathComponent(lastcomponent)
        url.appendPathComponent("Trident")
        return url
    } ()
    #elseif os(iOS)
    static let moviesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    #endif
    
    override init() {
        super.init()
        // Instantiate session
        downloadSession.sessionDescription = Bundle.main.bundleIdentifier
        
        // Make Recordings directories
        RecordingsAPI.setupRecodingsDirs()
    }
    
    static func setupRecodingsDirs() {
        let fileManager = FileManager.default
        let pilotURL = RecordingsAPI.moviesURL.appendingPathComponent(RecordingsAPI.pilotPath)
        let downloadsURL = RecordingsAPI.moviesURL.appendingPathComponent(RecordingsAPI.downloadsPath)
        try? fileManager.createDirectory(at: pilotURL, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
    }

    func setup(remoteAddress: String, delegate: RecordingsAPIProtocol) {
        baseURL = "http://\(remoteAddress):3000/recordings/"
        self.delegate = delegate
    }
    
    func videoURL(recording: Recording) -> URL {
        URL(string: baseURL! + recording.segments[0].uri)!
    }

    func previewURL(recording: Recording) -> URL {
        URL(string: baseURL! + recording.previewUri)!
    }
    
    func deleteURL(sessionId: String) -> URL {
        URL(string: baseURL! + sessionId)!
    }
    
    func recordingsURL() -> URL {
        URL(string: baseURL!)!
    }

    class func fileName(recording: Recording) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-hhmmss"
        let fileDateLabel = dateFormatter.string(from: recording.startTimestamp)
        return "\(downloadsPath)/Trident-\(fileDateLabel)-HQ.mp4"
    }
    
    class func pilotFileName(startTimestamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-hhmmss"
        let fileDateLabel = dateFormatter.string(from: startTimestamp)
        return "\(pilotPath)/Trident-\(fileDateLabel).mov"
    }

    func requestRecordings(completion: @escaping (Result<[Recording], NetworkError>) -> Void) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: recordingsURL())
        request.httpMethod = "GET"
        let asyncCompletion = { (result: Result<[Recording], NetworkError>) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard error == nil else {
                asyncCompletion(Result.failure(.unaviable(message: error!.localizedDescription)))
                return
            }
            let statusCode = (response as! HTTPURLResponse).statusCode
            guard (200..<300).contains(statusCode) else {
                let error = NetworkError.serverError(code: statusCode)
                asyncCompletion(Result.failure(error))
                return
            }
            guard let data = data else {
                asyncCompletion(Result.success([]))
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(Date.iso8601FullFormatter)
            do {
                let recordingResponce = try decoder.decode(RecordingsResponce.self, from: data)
                asyncCompletion(Result.success(recordingResponce.recordings))
            } catch {
                asyncCompletion(Result.failure(.responceSyntaxError(message: error.localizedDescription)))
            }
            
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func deleteRecording(with sessionId: String, completion: @escaping (NetworkError?) -> Void) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: deleteURL(sessionId: sessionId))
        request.httpMethod = "DELETE"

        let asyncCompletion = { (error: NetworkError?) in
            DispatchQueue.main.async {
                completion(error)
            }
        }
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard error == nil else {
                asyncCompletion(.unaviable(message: error!.localizedDescription))
                return
            }
            let statusCode = (response as! HTTPURLResponse).statusCode
            guard (200..<300).contains(statusCode) else {
                asyncCompletion(.serverError(code: statusCode))
                return
            }
            asyncCompletion(nil)
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }

    func download(recording: Recording) {
        let downloadURL = videoURL(recording: recording)
        let task = downloadSession.downloadTask(with: downloadURL)
        task.countOfBytesClientExpectsToSend = Int64(recording.segments[0].size/8)
        task.countOfBytesClientExpectsToReceive = Int64(recording.segments[0].size)
        task.taskDescription = recording.sessionId + ":" + RecordingsAPI.fileName(recording: recording)
        task.resume()
    }
    
    func isDownloaded(recording: Recording) -> Bool {
        let file = RecordingsAPI.fileName(recording: recording)
        let destination = RecordingsAPI.moviesURL.appendingPathComponent(file)
        let attibutes = try? FileManager.default.attributesOfItem(atPath: destination.path)
        let fileSize = attibutes?[.size] as? NSNumber
        return fileSize?.int64Value == Int64(recording.segments[0].size)
    }
    
    func getDownloads(completion: @escaping ([String: (Int64, Int64)]) -> Void) {
        downloadSession.getAllTasks { tasks in
            var progressList: [String: (Int64, Int64)] = [:]
            for task in tasks {
                task.resume()
                if let sessionId = task.taskDescription?.split(separator: ":").compactMap({String($0)}).first {
                    progressList[sessionId] = (task.countOfBytesReceived, task.countOfBytesExpectedToReceive)
                }
            }
            DispatchQueue.main.async {
                completion(progressList)
            }
        }
    }
    
    func cancelDownloads() {
        downloadSession.getAllTasks { tasks in
            tasks.forEach{ $0.cancel() }
        }
    }
}

extension RecordingsAPI: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard
            let taskData = downloadTask.taskDescription?.split(separator: ":"),
            taskData.count == 2 else {
                assertionFailure("\(#function) bad session")
                return
        }
        let sessionId = String(taskData[0])
        let fileName = String(taskData[1])
        let destination = RecordingsAPI.moviesURL.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        do {
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: location, to: destination)
        } catch {
            print(error)
        }
        DispatchQueue.main.async {
            self.delegate?.downloadEnd(sessionId: sessionId)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        guard
            let taskData = task.taskDescription?.split(separator: ":"),
            taskData.count == 2 else {
                assertionFailure("\(#function) bad session")
                return
        }
        let sessionId = String(taskData[0])
        DispatchQueue.main.async {
            self.delegate?.downloadError(sessionId: sessionId, error: error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard
            let taskData = downloadTask.taskDescription?.split(separator: ":"),
            taskData.count == 2 else {
                assertionFailure("\(#function) bad session")
                return
        }
        let sessionId = String(taskData[0])

        DispatchQueue.main.async {
            self.delegate?.progress(sessionId: sessionId, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
}

extension RecordingsAPI: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundSessionCompletionHandler?()
            self.backgroundSessionCompletionHandler = nil
        }
    }
}

extension URLSessionTask.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .running: return "running"
        case .suspended: return "suspended"
        case .canceling: return "canceling"
        case .completed: return "completed"
        @unknown default: return "unknown"
        }
    }
    
}
