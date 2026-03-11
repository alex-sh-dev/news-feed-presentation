//
//  Device.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/23/26.
//

import UIKit

extension UIDevice {
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
