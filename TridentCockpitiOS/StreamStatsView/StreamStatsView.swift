/////
////  StreamStatsView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import FastRTPSBridge
import CoreLocation

class StreamStatsView: FloatingView {
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

    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        // Top left corner
        let cph = (superview!.frame.minX + bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.minY + superview!.safeAreaInsets.top + offsetFromTop + bounds.midY) / superview!.frame.height
        print(superview!.safeAreaInsets.top, superview!.safeAreaLayoutGuide)
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.streamStatsViewCPH = cp.x
        Preference.streamStatsViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard
            let cph = Preference.streamStatsViewCPH,
            let cpv = Preference.streamStatsViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }

    // MARK: Instaniate
    static func instantiate(offsetFromTop: CGFloat) -> StreamStatsView {
        let nib = UINib(nibName: "StreamStatsView", bundle: nil)
        let views = nib.instantiate(withOwner: StreamStatsView(), options: nil)
        let view = views.first as! StreamStatsView
        view.offsetFromTop = offsetFromTop
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
