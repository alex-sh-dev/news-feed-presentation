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

    func setNewsItem(_ item: NewsItemNode, forId id: UInt) {
        self.news.setValue(NewsItem(with: item), forKey: id)
    }

    private init() {}
}
