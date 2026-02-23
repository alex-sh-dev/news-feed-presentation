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
    @IBOutlet weak var categoryLabel: InsetLabel!
    @IBOutlet weak var showInFullButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var showInFullHeightConstraint: NSLayoutConstraint! {
        didSet {
             savedHeightConstant = self.showInFullHeightConstraint.constant
        }
    }
    
    private var savedHeightConstant: CGFloat = 0
    
    var showInFullTappedHandler: (() -> Void)? = nil
    var shareTappedHandler: (() -> Void)? = nil
    
    @IBAction func showInFullTapped(_ sender: Any) {
        self.showInFullTappedHandler?()
    }
    
    @IBAction func shareTapped(_ sender: Any) {
        self.shareTappedHandler?()
    }
    
    func hideShowInFullButton(_ hidden: Bool) {
        self.showInFullButton.isHidden = hidden
        self.showInFullHeightConstraint.constant = hidden ? 0 : self.savedHeightConstant
    }
}
