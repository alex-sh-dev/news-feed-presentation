//
//  NewsItemCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

class NewsItemCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    static let identifier = "NewsItemCellIdentifier"
}
