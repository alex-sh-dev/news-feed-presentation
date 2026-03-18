//
//  NewsItemCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

protocol NewsItemCellDelegate: AnyObject {
    func onShowInFull(for cell: NewsItemCell)
    func onShare(for cell: NewsItemCell)
}

class NewsItemCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: InsetLabel!
    @IBOutlet weak var showInFullButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var showInFullHeightConstraint: NSLayoutConstraint! {
        didSet {
             savedHeightConstant = self.showInFullHeightConstraint.constant
        }
    }

    private var savedHeightConstant: CGFloat = 0

    var newsItemId: UInt = 0
    weak var delegate: NewsItemCellDelegate?

    @IBAction func onShowInFull(_ sender: Any) {
        self.delegate?.onShowInFull(for: self)
    }
    
    @IBAction func onShare(_ sender: Any) {
        self.delegate?.onShare(for: self)
    }
    
    func hideShowInFullButton(_ hidden: Bool) {
        self.showInFullButton.isHidden = hidden
        self.showInFullHeightConstraint.constant = hidden ? 0 : self.savedHeightConstant
    }

    func configure(with newsItem: NewsItem) {
        self.newsItemId = newsItem.value.id
        self.titleLabel.text = newsItem.value.title
        self.dateLabel.text = newsItem.value.publishedDate?.relativeDate()
        self.categoryLabel.text = newsItem.value.categoryType
        self.descriptionLabel.text = newsItem.value.description

        if newsItem.expanded {
            self.descriptionLabel.text = newsItem.text
            self.hideShowInFullButton(true)
        } else {
            let hidden = newsItem.value.fullUrl == nil
            self.hideShowInFullButton(hidden)
            self.shareButton.isHidden = hidden
        }
    }
}
