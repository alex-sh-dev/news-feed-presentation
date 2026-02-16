//
//  NewsItemImageCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/12/26.
//

import UIKit

class NewsItemImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func setDefaultImage() {
        setDefaultImage(for: self.imageView)
    }
}
