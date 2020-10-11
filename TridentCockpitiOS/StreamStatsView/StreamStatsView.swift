/////
////  StreamStatsView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import FastRTPSBridge

class StreamStatsView: UIView {
    @IBOutlet weak var streamStateLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var bpsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = 3
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(named: "cameraControlBackground")!
        fpsLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        bpsLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    }

    // MARK: Instaniate
    static func instantiate() -> StreamStatsView {
        let nib = UINib(nibName: "StreamStatsView", bundle: nil)
        let views = nib.instantiate(withOwner: StreamStatsView(), options: nil)
        let view = views.first as! StreamStatsView
        return view
    }
}

extension StreamStatsView: VideoStreamerDelegate {
    func showError(_ error: StreamerError) { }
    
    func state(published: Bool) {
        DispatchQueue.main.async {
            self.streamStateLabel.text = published ? "Stream: live" : "Stream: disconnected"
            if !published {
                self.fpsLabel.text = nil
                self.bpsLabel.text = nil
            }
        }
    }
    
    func stats(fps: UInt16, bytesOutPerSecond: Int32, totalBytesOut: Int64) {
        DispatchQueue.main.async {
            self.fpsLabel.text = String(fps) + "fps"
            let bps = Double(bytesOutPerSecond) * 8 / (1024 * 1024)
            self.bpsLabel.text = String(format: "%.1fMbps", bps)
        }
    }
}
