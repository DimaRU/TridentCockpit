/////
////  DiveCollectionViewCell.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

class DiveCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var selectionImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: NFDownloadButton!
    
    var playButtonAction: (() -> Void)?
    var downloadButtonAction: (() -> Void)?
    @IBAction func playButtonTap(_ sender: Any) {
        playButtonAction?()
    }
    
    @IBAction func downloadButtonTap(_ sender: NFDownloadButton) {
        if sender.downloadState == .toDownload {
            downloadButtonAction?()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0
        selectionImage.isHidden = true
    }
    
    override func prepareForReuse() {
        DivePlayerViewController.shared?.removeFromContainer()
        downloadButton.downloadState = .toDownload
        selectionImage.isHidden = true
        layer.borderWidth = 0
        previewLabel.text = nil
        isSelected = false
    }
    
    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            selectionImage.isHidden = !isSelected
            layer.borderWidth = isSelected ? 3 : 0
        }
    }
}
