//
//  ActivityIndicator.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/24/26.
//

import UIKit

extension UIActivityIndicatorView {
    enum Action {
        case start
        case stop
    }
    
    func setAction(_ action: Action) {
        let start = action == .start
        self.isHidden = !start
        if start {
            self.startAnimating()
        } else {
            self.stopAnimating()
        }
    }
}
