//
//  BaseNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

class BaseNewsViewModel {
    private var newsUpdatedSubscriber: AnyCancellable!
    var identifiers: [UInt] = []
    
    init() {
        self.bindToPublishers()
    }
    
    func bindToPublishers() {
        let handler = newsUpdatedSubscriberHandler()
        self.newsUpdatedSubscriber = NewsParser.shared.newsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { ids in
                handler(ids)
            }
    }
    
    func newsUpdatedSubscriberHandler() -> ([UInt]) -> Void {
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
            NewsParser.shared.requestData(page: page, count: count)
        }
    }
}
