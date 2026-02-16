//
//  CollectionCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/15/26.
//

import UIKit

extension UICollectionViewCell {
    static func dequeueReusableCell<CollectionCell: UICollectionViewCell>(from cv: UICollectionView, for indexPath: IndexPath, cast type: CollectionCell.Type) -> CollectionCell {
        let identifier = String(describing: CollectionCell.self) + "Identifier"
        guard let cell = cv.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? CollectionCell else {
            fatalError("Error: couldn't create cell with identifier: '\(identifier)'. Please, check storyboard/xib")
        }

        return cell
    }
}

extension UICollectionViewCell {
    func setDefaultImage(for imageView: UIImageView) {
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray
    }
}
