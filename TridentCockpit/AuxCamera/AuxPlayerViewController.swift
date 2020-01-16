/////
////  AuxPlayerViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVKit

class AuxPlayerViewController: NSViewController {
    let playerView = AVPlayerView()

    var videoURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        playerView.controlsStyle = .inline
        playerView.videoGravity = .resizeAspect
        playerView.showsFullScreenToggleButton = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let player = AVPlayer(url: videoURL)
        playerView.player = player
        player.rate = 1
        player.volume = 0
    }
}
