/////
////  PlayDemoVideo.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVKit

#if DEBUG
extension DiveViewController {
    private func createPlayerLayer(on view: UIView) -> AVPlayerLayer {
        let playerLayer = AVPlayerLayer()
        view.layer.addSublayer(playerLayer)
        playerLayer.frame = view.layer.bounds
        return playerLayer
    }
    
    func playDemoVideo() {
        guard let filePath = ProcessInfo.processInfo.environment["demoVideo"] else { return }
        FastRTPS.removeReader(topic: .rovDepth)
        FastRTPS.removeReader(topic: .rovTempWater)
        FastRTPS.removeReader(topic: .rovCamFwdH2640Video)
        depthLabel.text = "12.4"
        tempLabel.text = "28.3"
        stabilizeLabel.text = "Stabilized"
        
        let videoURL = URL(fileURLWithPath: filePath)
        let player = AVPlayer(url: videoURL)
        let playerLayer = createPlayerLayer(on: videoView)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        player.play()
        player.seek(to: .init(seconds: 5, preferredTimescale: 10000))
        
        let auxPlayerLayer = createPlayerLayer(on: liveViewContainer)
        auxPlayerLayer.player = AVPlayer(url: videoURL)
        auxPlayerLayer.player?.play()
        liveViewContainer.isHidden = false

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.restartDemoVideo()
            }
        }
    }
    
    private func restartDemoVideo() {
        let avPlayerLayer = (videoView.layer.sublayers?.first(where: { $0 is AVPlayerLayer })) as? AVPlayerLayer
        let auxPlayerLayer = (liveViewContainer.layer.sublayers?.first(where: { $0 is AVPlayerLayer })) as? AVPlayerLayer
        avPlayerLayer?.player?.seek(to: .init(seconds: 5, preferredTimescale: 10000))
        avPlayerLayer?.player?.play()
        auxPlayerLayer?.player?.seek(to: .zero)
        auxPlayerLayer?.player?.play()
    }
    
}
#endif
