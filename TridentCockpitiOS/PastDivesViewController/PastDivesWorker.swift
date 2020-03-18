/////
////  PastDivesWorker.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import Alamofire

extension Recording {
    func fileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-hhmmss"
        let fileDateLabel = dateFormatter.string(from: self.startTimestamp)
#if os(iOS)
        let moviesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = moviesURL.appendingPathComponent("Trident-\(fileDateLabel)-HQ.mp4")
#else
        let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .allDomainsMask).first!
        let fileURL = moviesURL.appendingPathComponent("Trident/Trident-\(fileDateLabel)-HQ.mp4")
#endif
        return fileURL
    }
}

protocol PastDivesProtocol: class {
    func deleteItem(for recording: Recording)
    func markItemDownloaded(for recording: Recording)
    func presentProgess(sheet: UIViewController)
}


final class PastDivesWorker {
    let backgroudQueue = DispatchQueue(label: "Trident.background.worker", qos: .background, attributes: [])
    var semaphore: DispatchSemaphore!
    let progressSheet = ProgressSheetController()
    var isCancelled = false
    var downloadRequest: DownloadRequest?
    weak var delegate: PastDivesProtocol?
    var count = 0
    var totalSize = 0
    var currentSize = 0

    public func download(recordings: [Recording], deleteAfter: Bool) {
        progressSheet.delegate = {
            self.downloadRequest?.cancel()
            self.isCancelled = true
        }
        
        progressSheet.headerLabel.text = "Download dive video"
        progressSheet.totalProgressView.progressValue = 0
        totalSize = recordings.reduce(0, { $0 + $1.segments[0].size })
        delegate?.presentProgess(sheet: progressSheet)

        count = 0
        currentSize = 0
        isCancelled = false
        downloadRequest = nil
        
        backgroudWorker(recordings: recordings) { recording in
            let fileURL = recording.fileURL()
            self.currentSize += recording.segments[0].size
            DispatchQueue.main.sync {
                self.progressSheet.fileNameLabel.text = fileURL.lastPathComponent
                self.progressSheet.fileProgressView.progressValue = 0
                self.progressSheet.fileCountLabel.text = "Files downloaded \(self.count)/\(recordings.count)"
                self.count += 1
            }
            self.downloadRequest = RecordingsAPI.download(recording: recording,
                                                          fileURL: fileURL,
                                                          progress: {
                                                            self.progressSheet.fileProgressView.progressValue = CGFloat($0.fractionCompleted * 100)
                                                            var progress = Double(self.currentSize - recording.segments[0].size) / Double(self.totalSize)
                                                            progress += Double(recording.segments[0].size) / Double(self.totalSize) * $0.fractionCompleted
                                                            self.progressSheet.totalProgressView.progressValue = CGFloat(progress * 100)
            })
            { error in
                if let error = error {
                    self.show(error: error)
                    return
                }
                if deleteAfter {
                    RecordingsAPI.deleteRecording(with: recording.sessionId) { error in
                        if let error = error {
                            self.show(error: error)
                            return
                        }
                        self.delegate?.deleteItem(for: recording)
                        self.semaphore.signal()
                    }
                } else {
                    self.delegate?.markItemDownloaded(for: recording)
                    self.semaphore.signal()
                }
            }
        }
    }
    
    public func delete(recordings: [Recording]) {
        progressSheet.delegate = {
            self.isCancelled = true
        }
        
        progressSheet.headerLabel.text = "Delete dive video"
        progressSheet.totalProgressView.progressValue = 100
        delegate?.presentProgess(sheet: progressSheet)

        count = 0
        isCancelled = false

        backgroudWorker(recordings: recordings) { recording in
            let fileURL = recording.fileURL()
            DispatchQueue.main.sync {
                self.progressSheet.fileNameLabel.text = fileURL.lastPathComponent
                self.progressSheet.fileProgressView.progressValue = 0
                self.progressSheet.fileCountLabel.text = "Deleted files \(self.count)/\(recordings.count)"
                self.progressSheet.totalProgressView.progressValue = CGFloat(self.count) / CGFloat(recordings.count) * 100
                self.count += 1
            }
            RecordingsAPI.deleteRecording(with: recording.sessionId)
            { error in
                if let error = error {
                    self.show(error: error)
                    return
                }
                self.delegate?.deleteItem(for: recording)
                self.semaphore.signal()
            }
        }
    }

    private func show(error: AFError) {
        self.isCancelled = true
        self.semaphore.signal()
        if case .explicitlyCancelled = error { return }

//        let alert = NSAlert(error: error)
//        alert.beginSheetModal(for: NSApp.mainWindow!)
    }
    
    private func backgroudWorker(recordings: [Recording], block: @escaping (Recording) -> Void) {
        semaphore = DispatchSemaphore(value: 0)
        backgroudQueue.async {
            for recording in recordings {
                if self.isCancelled { break }
                block(recording)
                self.semaphore.wait()
            }
            DispatchQueue.main.sync {
                if self.progressSheet.presentingViewController != nil {
                    self.progressSheet.dismiss(animated: true)
                }
            }
        }
    }
}
