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
    
    var actionHandler: (() -> Void)?

    @IBAction func playButtonTap(_ sender: Any) {
        actionHandler?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0
    }
    
    override func prepareForReuse() {
        selectionImage.isHidden = true
        layer.borderWidth = 0
        previewLabel.text = nil
    }
    
    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            selectionImage.isHidden = !isSelected
            layer.borderWidth = isSelected ? 3 : 0
        }
    }
}
