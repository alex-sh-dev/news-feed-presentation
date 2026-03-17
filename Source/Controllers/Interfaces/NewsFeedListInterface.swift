//
//  NewsFeedListInterface.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/17/26.
//

import UIKit

protocol NewsFeedListInterface {
    associatedtype NewsFeedDetailsType: NewsFeedDetailsInterface
    func startIdentifierToScrollItem(for details: NewsFeedDetailsType, sender: Any?) -> NewsFeedDetailsType.NewsItemIdentifierType
}
