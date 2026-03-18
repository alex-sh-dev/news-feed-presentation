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
        let storage = NewsStorage.shared
        storage.setText(parseTask.finalText, id: id)
        if let urls = parseTask.finalImageUrls {
            storage.setImageUrls(urls, id: id)
        }

        self.newsItemUpdatedPub.send(id)
        easyLog("news item with id = \(id) parsed")
    }

    final func cancelTask(id: UInt) {
        if let stask = self.sessionDataTasks.value(forKey: id) {
            stask.cancel()
        }
        if let ptask = self.parseTasks.value(forKey: id) {
            ptask.cancel()
        }
    }

    final func cancelAllTasks() {
        self.sessionDataTasks.forEach { _, task in
            task.cancel()
        }
        self.parseTasks.forEach { _, task in
            task.cancel()
        }
    }

    func request(subUrl: URL, for id: UInt) {
        if self.sessionDataTasks.containsKey(id)
            || self.sessionDataTasks.containsKey(id) {
            return
        }

        let endpoint = self.config.newsItemEndpoint!
            .appending(path: subUrl.absoluteString)
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = self.config.requestTimeoutSec

        let task = URLSession.shared.dataTaskPublisher(for: request)
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
                let task = Task() {
                    await self.startParseTask(parseTask)
                    self.parseTasks.removeValue(forKey: id)
                }
                self.parseTasks.setValue(task, forKey: itemId)
            })
        self.sessionDataTasks.setValue(task, forKey: id)
    }
}
