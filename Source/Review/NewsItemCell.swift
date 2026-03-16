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

    func configure(with id: UInt, from model: NewsFeedViewModel) {
        let newsItem = model.newsItem(at: id)!
        self.newsItemId = id
        self.titleLabel.text = newsItem.title
        self.dateLabel.text = newsItem.publishedDate?.relativeDate()
        self.categoryLabel.text = newsItem.categoryType
        self.descriptionLabel.text = newsItem.description

        if model.showInFullPressed.contains(id) {
            self.descriptionLabel.text = model.newsItemText(for: id)
            self.hideShowInFullButton(true)
        } else {
            let hidden = newsItem.fullUrl == nil
            self.hideShowInFullButton(hidden)
            self.shareButton.isHidden = hidden
        }
    }
}
