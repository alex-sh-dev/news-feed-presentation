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
    
    private static var config: WebConfig?
    private let newsEndpoint: URL!
    
    private var cancellable = [String: AnyCancellable]()
    let newsUpdatedPub = PassthroughSubject<[UInt], Never>()
    let newsItemParser: NewsItemParser!
    
    private init() {
        guard let config = NewsParser.config else {
            fatalError("Error: you must call setup before accessing NewsParser.shared")
        }
        
        if config.newsEndpoint == nil || config.newsItemEndpoint == nil {
            fatalError("Error: endpoint(s) are not specified")
        }
        
        newsItemParser = NewsItemParser(config: config)
        self.newsEndpoint = config.newsEndpoint
    }
    
    class func setup(_ config: WebConfig) {
        NewsParser.config = config
    }
    
    func requestNews(page: UInt = 1, count: UInt) {
        easyLog("page = \(page); count = \(count)")
        let endpoint = self.newsEndpoint!
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
                [unowned self] result in
                guard let news = result.news, !news.isEmpty else {
                    self.newsUpdatedPub.send([])
                    return
                }
                
                var ids = [UInt]()
                for newsItem in news {
                    let storage = NewsStorage.shared
                    storage.lock.with {
                        storage.news[newsItem.id] = newsItem
                    }
                    ids.append(newsItem.id)
                    if let subUrl = newsItem.url {
                        self.newsItemParser.requestNewsItem(subUrl: subUrl, for: newsItem.id)
                    }
                }
                easyLog("data received")
                self.newsUpdatedPub.send(ids)
                self.cancellable.removeValue(forKey: uuid)
            })
        self.cancellable[uuid] = cancellable
    }
}
