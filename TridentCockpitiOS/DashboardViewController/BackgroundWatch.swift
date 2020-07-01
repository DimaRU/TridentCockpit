/////
////  BackgroundWatch.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

protocol BackgroundWatchProtocol: class {
    func didEnterBackground()
    func willEnterForeground()
}

final class BackgroundWatch {
    private var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    var timer: Timer?
    weak var delegate: BackgroundWatchProtocol?
    private enum State {
        case foreground
        case background
        case transitionBg
        case stop
    }
    private var state: State = .foreground

    init(delegate: BackgroundWatchProtocol) {
        self.delegate = delegate
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil,
                                               queue: nil,
                                               using: willEnterForeground(_:))
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                               object: nil,
                                               queue: nil,
                                               using: didEnterBackground(_:))
        startBackgroundTask()
    }
    
    private func didEnterBackground(_ notification: Notification) {
        state = .background
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
            self.state = .transitionBg
            self.delegate?.didEnterBackground()
            self.stopBackgroundTask()
            self.state = .stop
        }
    }
    
    private func willEnterForeground(_ notification: Notification) {
        timer?.invalidate()
        timer = nil

        switch state {
        case .foreground:
            return
        case .background:
            state = .foreground
        case .transitionBg:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.state = .foreground
                self.delegate?.willEnterForeground()
                self.startBackgroundTask()
            }
        case .stop:
            state = .foreground
            delegate?.willEnterForeground()
        }
    }
    
    private func startBackgroundTask() {
        if #available(macCatalyst 13.0, *) {
        } else {
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Trident Cockpit") {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                self.state = .stop
            }
        }
    }
    
    private func stopBackgroundTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
}
