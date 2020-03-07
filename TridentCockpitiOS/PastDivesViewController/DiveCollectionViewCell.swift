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
    
    
    @IBAction func playButtonTap(_ sender: Any) {
    }
}
