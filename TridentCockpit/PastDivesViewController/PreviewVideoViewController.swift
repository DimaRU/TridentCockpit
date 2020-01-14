/////
////  AuxPlayerViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import AVKit

class PreviewVideoViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    
    var isMouseInWindow = false
    var videoURL: URL! {
        didSet {
            let player = AVPlayer(url: videoURL)
            playerView.player = player
            player.rate = 1
            title = videoURL.absoluteString
        }
    }
    var videoTitle: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
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
