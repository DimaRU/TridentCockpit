/////
////  PreviewVideoViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVKit

class PreviewVideoViewController: NSViewController {
    let playerView = AVPlayerView()
    
    var isMouseInWindow = false
    var videoURL: URL! {
        didSet {
            let player = AVPlayer(url: videoURL)
            playerView.player = player
            player.rate = 1
        }
    }
    var videoTitle: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16.0/9.0),
        ])
        playerView.controlsStyle = .inline
        playerView.videoGravity = .resizeAspect
        playerView.showsFullScreenToggleButton = true
    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = videoTitle
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard !isMouseInWindow else { return }
        isMouseInWindow = true
        view.window!.styleMask.insert([.utilityWindow, .titled])
    }
    
    override func mouseExited(with event: NSEvent) {
        isMouseInWindow = false
        view.window!.styleMask.remove(.titled)
    }
}
