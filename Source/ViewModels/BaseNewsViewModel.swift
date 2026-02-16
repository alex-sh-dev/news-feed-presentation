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
    private(set) var requestItemsCount: Int! = 0
    var identifiers: [UInt] = []
    
    init(requestItemsFor count: UInt = 0) {
        self.requestItemsCount = Int(count)
        self.bindToPublishers()
        self.requestItems(count: count)
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
    
    public func newsItem(at id: UInt) -> NewsItem? {
        var newsItem: NewsItem?
        NewsStorage.shared.lock.with {
            newsItem = NewsStorage.shared.news[id]
        }

        return newsItem
    }

    public func requestItems(page: UInt = 1, count: UInt) {
        if count > 0 {
            NewsParser.shared.requestData(page: page, count: count)
        }
    }
}
