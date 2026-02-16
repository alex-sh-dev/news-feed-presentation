//
//  PreviewNewsItemCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

class PreviewNewsItemCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    var itemIdentifier: NewsItemIdentifier = .notValid
    
    private struct Constants {
        static let kDefDuration = 0.2
        static let kMinTfScale = 0.9
        static let kOrigTfScale = 1.0
    }
    
    private func animateSelection(animations: @escaping () -> Void) {
        UIView.animate(withDuration: Constants.kDefDuration, delay: 0,
                       options: .curveEaseOut, animations: animations, completion: nil)
    }
    
    func setDefaultImage() {
        setDefaultImage(for: self.imageView)
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                animateSelection {
                    let scale = Constants.kMinTfScale
                    self.transform = self.transform.scaledBy(x: scale, y: scale)
                }
            } else {
                animateSelection {
                    let scale = Constants.kOrigTfScale
                    self.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
                }
            }
        }
    }
}
