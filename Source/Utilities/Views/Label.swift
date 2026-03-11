//
//  Label.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/13/26.
//

import UIKit

extension UIEdgeInsets {
    public static var defaultLabelPadding: UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
}

class InsetLabel: UILabel {
    var edgeInsets: UIEdgeInsets = .defaultLabelPadding
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.edgeInsets))
    }
    
    override public var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height += edgeInsets.top + edgeInsets.bottom
        intrinsicContentSize.width += edgeInsets.left + edgeInsets.right
        return intrinsicContentSize
    }
}

class CenteredLabel: UILabel {
    init(text: LocalizedStringResource, parent: UIView) {
        super.init(frame: .zero)
        self.text = String(localized: text)
        self.textColor = UIColor.secondaryLabel
        self.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: parent.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
