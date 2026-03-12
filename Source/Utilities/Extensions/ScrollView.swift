//
//  ScrollView.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/13/26.
//

import UIKit

extension UIScrollView {
    func reachedBottom() -> Bool {
        let offsetY = self.contentOffset.y
        let contentHeight = self.contentSize.height
        let frameHeight = self.frame.size.height

        if offsetY >= contentHeight - frameHeight {
            return true
        }

        return false
    }
}
