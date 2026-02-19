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
    
    private var cancellable = [String: AnyCancellable]()
    private let operationSerialQueue = AsyncOperationQueue()
    
    let imageUrlsUpdatedPublisher = PassthroughSubject<UInt, Never>()
    let newsItemTextUpdatedPublisher = PassthroughSubject<UInt, Never>()
    
    init(config: WebConfig) {
        self.config = config
    }
    
    private func addParseTask(_ parseTask: NewsItemParseTask) {
        self.operationSerialQueue.enqueue { [weak self] in
            guard let self = self else { return }
            
            guard let id = parseTask.id else {
                return
            }
            
            parseTask.start()
            
            let storage = NewsStorage.shared
            storage.lock.with {
                storage.fullTextContents[id] = parseTask.finalText
                self.newsItemTextUpdatedPublisher.send(id)
            }
            
            storage.lock.with {
                if let urls = parseTask.finalImageUrls {
                    storage.imageUrls[id] = urls
                    self.imageUrlsUpdatedPublisher.send(id)
                }
            }
        }
    }
    
//    NewsImageUrlsExtractor.shared.addTask(for: newsItem.titleImageUrl, with: newsItem.id)//??
    
    func requestNewsItem(subUrl: URL, for id: UInt) {
        let endpoint = self.config.newsItemEndpoint!
            .appending(path: subUrl.absoluteString)
            
        let uuid = UUID().uuidString
        let cancellable = URLSession.shared.dataTaskPublisher(for: endpoint)
            .map { $0.data }
            .retry(self.config.requestAttemptsCount)
            .decode(type: TextNewsItem.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in
            }, receiveValue: { [weak self] result in
                guard let text = result.text else {
                    return
                }
                let parseTask = NewsItemParseTask(text: text, titleImageUrl: result.titleImageUrl, for: id)
                self?.addParseTask(parseTask)
                DispatchQueue.main.async { [weak self] in
                    self?.cancellable.removeValue(forKey: uuid)
                }
            })
        self.cancellable[uuid] = cancellable
    }
    
   
}


