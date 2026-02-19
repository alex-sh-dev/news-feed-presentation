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
        var newsEndpoint: URL?
        var newsItemEndpoint: URL?
        let requestAttemptsCount = 3
        
        init() {}
    }
    
    private static var config: Config?
    var newsEndpoint: URL?
    var newsItemEndpoint: URL?
    
    private var cancellable = [String: AnyCancellable]()
    let newsUpdatedPublisher = PassthroughSubject<[UInt], Never>()
    private let operationSerialQueue = AsyncOperationQueue()
    
    private init() {
        guard let config = NewsParser.config else {
            fatalError("Error: you must call setup before accessing NewsParser.shared")
        }
        
        self.newsEndpoint = config.newsEndpoint
        self.newsItemEndpoint = config.newsItemEndpoint
        
        if self.newsEndpoint == nil || self.newsItemEndpoint == nil {
            fatalError("Error: endpoint(s) are not specified")
        }
    }
    
    class func setup(_ config: Config) {
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
                [weak self] result in
                guard let news = result.news, !news.isEmpty else {
                    self?.newsUpdatedPublisher.send([])
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
                        self?.operationSerialQueue.enqueue { [weak self] in
                            self?.requestNewsItem(subUrl: subUrl)
                        }
                    }
                }
                easyLog("data received")
                self?.newsUpdatedPublisher.send(ids)
                self?.cancellable.removeValue(forKey: uuid)
            })
        self.cancellable[uuid] = cancellable
    }
    
    func requestNewsItem(subUrl: URL) {
        let endpoint = self.newsItemEndpoint!
            .appending(path: subUrl.absoluteString)
        
        let uuid = UUID().uuidString
        let cancellable = URLSession.shared.dataTaskPublisher(for: endpoint)
            .map { $0.data }
            .retry(NewsParser.config!.requestAttemptsCount)
            .decode(type: TextNewsItem.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in
            }, receiveValue: {
                result in
                guard let text = result.text else {
                    return
                }
                
                let parser = NewsItemParser(text: text)
                parser.parse()

                let storage = NewsStorage.shared
                storage.lock.with {
                    storage.fullTextContents[result.id] = parser.finalText
                    //?? publish 
                }
                
                if let url = result.titleImageUrl {
                    storage.lock.with {
                        storage.imageUrls[result.id] = parser.imageUrls(withExcludedUrl: url)
                        //?? publish
                    }
                }
                
//                NewsImageUrlsExtractor.shared.addTask(for: newsItem.titleImageUrl, with: newsItem.id)//??
                
                DispatchQueue.main.async { [weak self] in
                    easyLog("news item = \(subUrl) received")
                    self?.cancellable.removeValue(forKey: uuid)
                }
            })
        self.cancellable[uuid] = cancellable
    }
}
