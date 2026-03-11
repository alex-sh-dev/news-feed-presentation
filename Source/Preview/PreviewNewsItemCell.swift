//
//  PreviewNewsItemCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

class PreviewNewsItemCell: UICollectionViewCell {
    private struct Constants {
        static let kDefDuration = 0.2
        static let kMinTfScale = 0.9
        static let kOrigTfScale = 1.0
    }

    var itemIdentifier: NewsItemIdentifier = .notValid

    func configure(with title: String?, and imageURL: URL?) {
        var config = TitledImageContentConfiguration()
        config.title = title
        config.imageUrl = imageURL
        self.contentConfiguration = config
    }

    private func animateSelection(animations: @escaping () -> Void) {
        UIView.animate(withDuration: Constants.kDefDuration, delay: 0,
                       options: .curveEaseOut, animations: animations, completion: nil)
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                animateSelection { [unowned self] in
                    let scale = Constants.kMinTfScale
                    self.transform = self.transform.scaledBy(x: scale, y: scale)
                }
            } else {
                animateSelection { [unowned self] in
                    let scale = Constants.kOrigTfScale
                    self.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
                }
            }
        }
    }
}
