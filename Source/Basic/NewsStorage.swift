//
//  NewsStorage.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import Foundation

class NewsStorage {
    static let shared = NewsStorage()

    let lock = NSLock()
    private(set) var news = [UInt: NewsItem]()

    func addNewsItem(_ item: NewsItemNode) {
        self.news[item.id] = NewsItem(with: item)
    }

    func setText(_ text: String, id: UInt) {
        self.news[id]?.text = text
    }

    func setImageUrls(_ urls: [URL], id: UInt) {
        self.news[id]?.imageUrls = urls
    }

    private init() {}
}
