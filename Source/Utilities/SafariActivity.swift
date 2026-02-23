//
//  SafariActivity.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/23/26.
//

import UIKit

final class SafariActivity: UIActivity {
    var url: URL?
    
    override class var activityCategory: UIActivity.Category {
        return .action
    }
    
    override var activityImage: UIImage? {
        let conf = UIImage.SymbolConfiguration(scale: .large)
        return UIImage(systemName: "safari", withConfiguration: conf)!
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("Open in Safari", comment:"")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL,
                UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL,
               UIApplication.shared.canOpenURL(url) {
                self.url = url
            }
        }
    }
    
    override func perform() {
        if let url = self.url {
            UIApplication.shared.open(url, options: [:]) {
                [weak self] completed in
                self?.activityDidFinish(completed)
            }
        }
    }
}
