//
//  NewsItem.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/18/26.
//

import Foundation

class NewsItem {
    var value: NewsItemNode!
    var text: String?
    var expanded: Bool = false
    var imageUrls: [URL] = []

    var id: UInt { value.id }

    init(with item: NewsItemNode) {
        self.value = item
    }

    func jointImageUrls() -> [URL] {
        var urls: [URL] = []
        if let url = self.value.titleImageUrl {
            urls.append(url)
        }

        if !self.imageUrls.isEmpty {
            urls.append(contentsOf: self.imageUrls)
        }
        return urls
    }
}
