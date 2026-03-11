//
//  NewsItemImageCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/12/26.
//

import UIKit

class NewsItemImageCell: UICollectionViewCell {
    func configure(with url: URL) {
        var config = RemoteImageContentConfiguration()
        config.imageUrl = url
        self.contentConfiguration = config
    }
}
