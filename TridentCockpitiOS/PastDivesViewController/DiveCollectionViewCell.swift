/////
////  DiveCollectionViewCell.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

protocol DiveCollectionViewCellDelegate: AnyObject {
    func playButtonAction(cell: DiveCollectionViewCell)
    func downloadButtonAction(cell: DiveCollectionViewCell)
}

class DiveCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var selectionImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: SmartDownloadButton!

    weak var delegate: DiveCollectionViewCellDelegate?

    @IBAction func playButtonTap(_ sender: Any) {
        delegate?.playButtonAction(cell: self)
    }

    @IBAction func downloadButtonTap(_ sender: Any) {
        delegate?.downloadButtonAction(cell: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0
        selectionImage.isHidden = true
    }
    
    override func prepareForReuse() {
        DivePlayerViewController.shared?.removeFromContainer()
        delegate = nil
        downloadButton.downloadState = .start
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
