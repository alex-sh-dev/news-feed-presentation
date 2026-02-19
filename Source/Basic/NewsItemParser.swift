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
    private let operationSerialQueue = AsyncOperationQueue()
    
    let newsItemUpdatedPub = PassthroughSubject<UInt, Never>()
    
    init(config: WebConfig) {
        self.config = config
    }
    
    private func startParseTask(_ parseTask: NewsItemParseTask) {
        guard let id = parseTask.id else {
            return
        }

        parseTask.start()

        let storage = NewsStorage.shared
        storage.lock.with {
            storage.fullTextContents[id] = parseTask.finalText
        }

        storage.lock.with {
            if let urls = parseTask.finalImageUrls {
                storage.imageUrls[id] = urls
            }
        }

        self.newsItemUpdatedPub.send(id)
        easyLog("news item with id = \(id) parsed")
    }
    
    private func request(for url: URL, with id: UInt) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        if data.isEmpty {
            return
        }
        
        let result = try JSONDecoder().decode(TextNewsItem.self, from: data)
        guard let text = result.text else {
            return
        }

        let parseTask = NewsItemParseTask(text: text, titleImageUrl: result.titleImageUrl, for: id)
        self.startParseTask(parseTask)
    }

    func requestNewsItem(subUrl: URL, for id: UInt) {
        let endpoint = self.config.newsItemEndpoint!
            .appending(path: subUrl.absoluteString)
        
        self.operationSerialQueue.enqueue { [weak self] in
            guard let self = self else { return }
            let maxRetries = self.config.requestAttemptsCount
            let delay = self.config.sendRequestDelayMs * NSEC_PER_MSEC
            for _ in 0..<maxRetries {
                do {
                    try await self.request(for: endpoint, with: id)
                    break
                } catch {
                    do {
                        try await Task.sleep(nanoseconds: delay)
                    } catch {}
                }
            }
        }
    }
}
