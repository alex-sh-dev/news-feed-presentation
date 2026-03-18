//
//  BaseNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

class BaseActingNewsViewModel<IdentifiersActionType>: BaseNewsViewModel {
    final let identifiersActionPub = PassthroughSubject<IdentifiersActionType, Never>()
}

class BaseNewsViewModel {
    private var newsUpdatedSub: AnyCancellable!
    var identifiers: [UInt] = []
    var desiredRequestedItemCount: UInt = 0

    required init() {
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

    func id(at index: UInt) -> UInt? {
        if index >= self.identifiers.count {
            return nil
        }
        return self.identifiers[Int(index)]
    }

    func requestItems(page: UInt = 1, count: UInt) -> Bool {
        if count > 0 {
            NewsParser.shared.requestNews(page: page, count: count)
            return true
        }

        return false
    }

    private func requestParams() -> (UInt, UInt) {
        let total = UInt(self.identifiers.count)
        let itemCount = max(self.desiredRequestedItemCount, 1)
        return (total, itemCount)
    }

    @discardableResult
    func requestNews() -> Bool {
        let (total, desiredItemCount) = requestParams()
        let page = (total + desiredItemCount) / desiredItemCount
        return self.requestItems(page: page, count: desiredItemCount)
    }

    func requestNewsIfNeeded(currentItemRow: UInt) {
        let (total, desiredItemCount) = requestParams()
        if currentItemRow == total - desiredItemCount / 2 {
            self.requestNews()
        }
    }

    func requestFullNewsItemIfNeeded(with id: UInt) {
        if let newsItem = self.newsItem(at: id),
           newsItem.text?.isEmpty ?? true,
           let subUrl = newsItem.value.url {
            NewsParser.shared.newsItemParser.request(subUrl: subUrl, for: id)
        }
    }

    func cancelFullNewsItemRequest(for id: UInt) {
        NewsParser.shared.newsItemParser.cancelTask(id: id)
    }

    func cancelAllFullNewsItemRequests() {
        NewsParser.shared.newsItemParser.cancelAllTasks()
    }

    func isEmpty() -> Bool {
        return self.identifiers.isEmpty
    }

    func clearExpandedStates() {
        let storage = NewsStorage.shared
        storage.lock.withLock {
            storage.news.forEach { _, item in
                item.expanded = false
            }
        }
    }

    static func createObject<T: BaseNewsViewModel>(fromType type: T.Type) -> T {
        return T.init()
    }
}
