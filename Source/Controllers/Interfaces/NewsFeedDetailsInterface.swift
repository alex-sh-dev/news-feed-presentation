//
//  NewsFeedDetailsInterface.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/17/26.
//

import UIKit

protocol NewsFeedDetailsInterface {
    func scrollToStartItem()
    typealias NewsItemIdentifierType = NewsItemIdentifier
    var startIdentifier: NewsItemIdentifierType { get set }
    static var segueIdentifier: SegueIdentifier { get }
}
