//
//  NewsStorage.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import Foundation

class NewsStorage {
    static let shared = NewsStorage()

    private(set) var news = ThreadSafeMap<UInt, NewsItem>()

    func addNewsItem(_ item: NewsItemNode) {
        self.news.setValue(NewsItem(with: item), forKey: item.id)
    }

    func setText(_ text: String, id: UInt) {
        self.news.updateValue(forKey: id) {
            item in
            item.text = text
        }
    }

    func setImageUrls(_ urls: [URL], id: UInt) {
        self.news.updateValue(forKey: id) {
            item in
            item.imageUrls = urls
        }
    }

    private init() {}
}
