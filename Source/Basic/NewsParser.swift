//
//  NewsParser.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import Foundation
import Combine

class NewsParser {
    static let shared = NewsParser()
    
    struct Config {
        let baseEndpoint: URL
        let requestAttemptsCount = 3
    }
    
    private static var config: Config?
    var baseEndpoint: URL
    
    private var cancellable = [String: AnyCancellable]()
    let newsUpdatedPublisher = PassthroughSubject<[UInt], Never>()
    
    private init() {
        guard let config = NewsParser.config else {
            fatalError("Error: you must call setup before accessing NewsParser.shared")
        }
        
        self.baseEndpoint = config.baseEndpoint
    }
    
    class func setup(_ config: Config) {
        NewsParser.config = config
    }
    
    func requestData(page: UInt = 1, count: UInt) {
        easyLog("page = \(page); count = \(count)")
        let endpoint = self.baseEndpoint
            .appending(path: String(page))
            .appending(path: String(count))
        
        let uuid = UUID().uuidString
        let cancellable = URLSession.shared.dataTaskPublisher(for: endpoint)
            .map { $0.data }
            .retry(NewsParser.config!.requestAttemptsCount)
            .decode(type: NewsNode.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .replaceError(with: NewsNode.zero)
            .eraseToAnyPublisher()
            .sink(receiveValue: {
                [weak self] result in
                guard let news = result.news, !news.isEmpty else {
                    self?.newsUpdatedPublisher.send([])
                    return
                }
                
                var ids = [UInt]()
                for newsItem in news {
                    let storage = NewsStorage.shared
                    var startExtractor = false
                    storage.lock.with {
                        storage.news[newsItem.id] = newsItem
                        startExtractor = storage.imageUrls.index(forKey: newsItem.id) == nil
                    }
                    ids.append(newsItem.id)
                    if startExtractor {
                        NewsImageUrlsExtractor.shared.addTask(for: newsItem.titleImageUrl, with: newsItem.id)
                    }
                }
                easyLog("data received")
                self?.newsUpdatedPublisher.send(ids)
                self?.cancellable.removeValue(forKey: uuid)
            })
        self.cancellable[uuid] = cancellable
    }
}
