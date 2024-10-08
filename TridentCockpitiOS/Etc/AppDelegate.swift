/////
////  AppDelegate.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Instantiate Recordings API
        _ = RecordingsAPI.shared
        
        var isAudioSessionSupported = false
        if #available(macCatalyst 14.0, *) {
            isAudioSessionSupported = true
        }
        if #available(iOS 13, *) {
            isAudioSessionSupported = true
        }
        
        if isAudioSessionSupported {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try session.setActive(true)
            } catch {
                print(error)
            }
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        RecordingsAPI.shared.backgroundSessionCompletionHandler = completionHandler
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        builder.remove(menu: .file)
        builder.remove(menu: .services)
        builder.remove(menu: .format)
        builder.remove(menu: .spelling)
        builder.remove(menu: .substitutions)
        builder.remove(menu: .transformations)
        builder.remove(menu: .speech)
        builder.remove(menu: .toolbar)
        builder.remove(menu: .help)
    }
}

