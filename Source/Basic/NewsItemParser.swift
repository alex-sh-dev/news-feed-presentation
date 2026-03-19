//
//  NewsItemParser.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/19/26.
//

import Foundation
import Combine

class NewsItemParser {
    private let config: WebConfig!

    private var sessionDataTasks = ThreadSafeMap<UInt, AnyCancellable>()
    private var parseTasks = ThreadSafeMap<UInt, Task<Void, Never>>()

    let newsItemUpdatedPub = PassthroughSubject<UInt, Never>()

    init(config: WebConfig) {
        self.config = config
    }

    private func startParseTask(_ parseTask: NewsItemParseTask) async {
        if !parseTask.start() {
            return
        }

        let id = parseTask.id!
        NewsStorage.shared.news.updateValue(forKey: id) {
            item in
            item.text = parseTask.finalText
            if let urls = parseTask.finalImageUrls {
                item.imageUrls = urls
            }
        }
        self.newsItemUpdatedPub.send(id)
        easyLog("news item with id = \(id) parsed")
    }

    final func cancelTask(id: UInt) {
        self.sessionDataTasks.updateValue(forKey: id) {
            task in task.cancel()
        }
        self.parseTasks.updateValue(forKey: id) {
            task in task.cancel()
        }
    }

    final func cancelAllTasks() {
        self.sessionDataTasks.updateForEach { _, task in task.cancel() }
        self.parseTasks.updateForEach { _, task in task.cancel() }
    }

    func request(subUrl: URL, for id: UInt) {
        if self.sessionDataTasks.containsKey(id)
            || self.parseTasks.containsKey(id) {
            return
        }

        let endpoint = self.config.newsItemEndpoint!
            .appending(path: subUrl.absoluteString)
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = self.config.requestTimeoutSec

        let stask = URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(receiveCancel: {
                [unowned self] in
                self.sessionDataTasks.removeValue(forKey: id)
            })
            .map { $0.data }
            .retry(self.config.requestAttemptsCount)
            .decode(type: TextNewsItemNode.self, decoder: JSONDecoder())
            .replaceError(with: TextNewsItemNode())
            .eraseToAnyPublisher()
            .sink(receiveValue: {
                [unowned self] item in
                defer {
                    self.sessionDataTasks.removeValue(forKey: id)
                }

                guard let itemId = item.id, itemId == id,
                      let text = item.text else {
                    return
                }

                let parseTask = NewsItemParseTask(text: text, titleImageUrl: item.titleImageUrl, for: itemId)
                let ptask = Task() {
                    await self.startParseTask(parseTask)
                    self.parseTasks.removeValue(forKey: id)
                }
                self.parseTasks.setValue(ptask, forKey: itemId)
            })
        self.sessionDataTasks.setValue(stask, forKey: id)
    }
}
