//
//  UICollectionView+Extensions.swift
//  PostDives
//
//  Created by Dmitriy Borovikov on 08.03.2020.
//  Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func dequeueCell<Cell: UICollectionViewCell>(of cellType: Cell.Type,
                                                 for indexPath: IndexPath) -> Cell {
        
        return dequeueReusableCell(withReuseIdentifier: String(describing: cellType),
                                   for: indexPath) as! Cell
    }
    
    func dequeueSupplementaryView<View: UICollectionReusableView>(of viewType: View.Type, kind: String, for indexPath: IndexPath) -> View {
        
        return dequeueReusableSupplementaryView(ofKind: kind,
                                                withReuseIdentifier: String(describing: viewType),
                                                for: indexPath) as! View
    }
    
}
