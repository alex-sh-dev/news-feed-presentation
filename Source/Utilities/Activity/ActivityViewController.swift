//
//  ActivityViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/23/26.
//

import UIKit

extension UIActivityViewController {
    static func linkOpener(url: URL, sourceView: UIView?) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [url], applicationActivities: [SafariActivity()])
        if UIDevice.isPad && sourceView != nil {
            UIActivityViewController.configurePopover(for: activityVC, sourceView: sourceView!)
        }
        
        return activityVC
    }
    
    static func configurePopover(for activityVC: UIActivityViewController, sourceView: UIView) {
        activityVC.modalPresentationStyle = .popover
        guard let popController = activityVC.popoverPresentationController else {
            return
        }
        popController.permittedArrowDirections = .any
        popController.sourceView = sourceView
    }
}
