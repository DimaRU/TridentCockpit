/////
////  AuxPlayerViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVKit

class AuxPlayerViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!

    var videoURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let player = AVPlayer(url: videoURL)
        playerView.player = player
        player.rate = 1
        player.volume = 0
    }
}
