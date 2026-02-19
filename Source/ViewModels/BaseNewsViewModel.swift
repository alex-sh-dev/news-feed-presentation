//
//  BaseNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

class BaseNewsViewModel {
    private var newsUpdatedSub: AnyCancellable!
    var identifiers: [UInt] = []
    
    init() {
        self.bindToPublishers()
    }
    
    func bindToPublishers() {
        let handler = newsUpdatedSubHandler()
        self.newsUpdatedSub = NewsParser.shared.newsUpdatedPub
            .receive(on: DispatchQueue.main)
            .sink { ids in
                handler(ids)
            }
    }
    
    func newsUpdatedSubHandler() -> ([UInt]) -> Void {
        return { _ in }
    }
    
    func newsItem(at id: UInt) -> NewsItem? {
        var newsItem: NewsItem?
        NewsStorage.shared.lock.with {
            newsItem = NewsStorage.shared.news[id]
        }

        return newsItem
    }

    func requestItems(page: UInt = 1, count: UInt) {
        if count > 0 {
            NewsParser.shared.requestNews(page: page, count: count)
        }
    }
}
