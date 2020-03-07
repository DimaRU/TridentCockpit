/////
////  PastDivesViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

class PastDivesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var availableSpaceBar: LinearProgressBar!
    @IBOutlet weak var availableSpaceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        availableSpaceBar.barColorForValue = { value in
            switch value {
            case 0..<10:
                return UIColor.red
            case 10..<20:
                return UIColor.yellow
            default:
                return UIColor.systemGreen
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            DispatchQueue.main.async {
                let level = Double(recordingStats.diskSpaceTotalBytes - recordingStats.diskSpaceUsedBytes) / Double(recordingStats.diskSpaceTotalBytes)
                let gigabyte: Double = 1000 * 1000 * 1000
                let total = Double(recordingStats.diskSpaceTotalBytes) / gigabyte
                let available = Double(recordingStats.diskSpaceTotalBytes - recordingStats.diskSpaceUsedBytes) / gigabyte
                self?.availableSpaceBar.progressValue = CGFloat(level) * 100
                self?.availableSpaceLabel.text = String(format: "%.1f GB of %.1f GB free", available, total)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FastRTPS.removeReader(topic: .rovRecordingStats)
    }
    
    
    @IBAction func selectAllButtonTap(_ sender: Any) {
    }
    
    @IBAction func deselectAllButtonTap(_ sender: Any) {
    }
    
    @IBAction func downloadButtonTap(_ sender: Any) {
    }
    
    @IBAction func deleteButtonTap(_ sender: Any) {
    }
    
}

extension UICollectionViewDataSource {
    
}

extension UICollectionViewDelegate {
    
}
