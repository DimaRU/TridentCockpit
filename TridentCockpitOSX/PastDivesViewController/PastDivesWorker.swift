/////
////  PastDivesWorker.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Cocoa
import Alamofire

extension Recording {
    func fileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-hhmmss"
        let fileDateLabel = dateFormatter.string(from: self.startTimestamp)
        let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .allDomainsMask).first!
        let fileURL = moviesURL.appendingPathComponent("/Trident/Trident-\(fileDateLabel)-HQ.mp4")
        return fileURL
    }
}

protocol PastDivesProtocol: class {
    func deleteItem(for recording: Recording)
    func markItemDownloaded(for recording: Recording)
}


final class PastDivesWorker {
    let backgroudQueue = DispatchQueue(label: "Trident.background.worker", qos: .background, attributes: [])
    var semaphore: DispatchSemaphore!
    var infoWindow: NSAlert!
    var isCancelled = false
    var downloadRequest: DownloadRequest?
    weak var delegate: PastDivesProtocol?

    public func download(recordings: [Recording], deleteAfter: Bool) {
        let progressIndicator = createProgressAlert(message: "Download dive video:")
        infoWindow.beginSheetModal(for: NSApp.mainWindow!) { responce in
            if responce == .alertFirstButtonReturn {
                // cancel
                self.downloadRequest?.cancel()
                self.isCancelled = true
            }
        }
        
        isCancelled = false
        downloadRequest = nil
        
        backgroudWorker(recordings: recordings) { recording in
            let fileURL = recording.fileURL()
            DispatchQueue.main.sync {
                progressIndicator.minValue = 0
                progressIndicator.maxValue = 1
                progressIndicator.doubleValue = 0
                self.infoWindow.informativeText = fileURL.lastPathComponent
            }
            self.downloadRequest = RecordingsAPI.download(recording: recording,
                                                    fileURL: fileURL,
                                                    progress: { progressIndicator.doubleValue = $0.fractionCompleted })
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
        let progressIndicator = createProgressAlert(message: "Delete video")
        infoWindow.beginSheetModal(for: NSApp.mainWindow!) { responce in
            if responce == .alertFirstButtonReturn {
                // cancel
                self.isCancelled = true
            }
        }
        
        isCancelled = false

        backgroudWorker(recordings: recordings) { recording in
            let fileURL = recording.fileURL()
            DispatchQueue.main.sync {
                progressIndicator.minValue = 0
                progressIndicator.maxValue = Double(recordings.count)
                progressIndicator.doubleValue = 0
                self.infoWindow.informativeText = fileURL.lastPathComponent
            }
            RecordingsAPI.deleteRecording(with: recording.sessionId)
            { error in
                if let error = error {
                    self.show(error: error)
                    return
                }
                progressIndicator.increment(by: 1)
                self.delegate?.deleteItem(for: recording)
                self.semaphore.signal()
            }
        }
    }

    private func createProgressAlert(message: String) -> NSProgressIndicator {
        infoWindow = NSAlert()
        infoWindow.addButton(withTitle: "Cancel")
        infoWindow.messageText = message
        let progressIndicator = NSProgressIndicator(frame: .init(x: 0, y: 0, width: 300, height: 10))
        progressIndicator.isIndeterminate = false
        infoWindow.accessoryView = progressIndicator
        return progressIndicator
    }
    
    private func show(error: AFError) {
        self.isCancelled = true
        self.semaphore.signal()
        if case .explicitlyCancelled = error { return }

        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: NSApp.mainWindow!)
    }
    
    private func backgroudWorker(recordings: [Recording], block: @escaping (Recording) -> Void) {
        semaphore = DispatchSemaphore(value: 0)
        backgroudQueue.async {
            for recording in recordings {
                if self.isCancelled { break }
                block(recording)
                self.semaphore.wait()
            }
            guard let infoWindow = self.infoWindow else { return }
            DispatchQueue.main.sync {
                NSApp.mainWindow?.endSheet(infoWindow.window)
                self.infoWindow = nil
            }
        }
    }
}
