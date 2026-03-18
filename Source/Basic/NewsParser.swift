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
    
    private var runningTasks = [String: AnyCancellable]()
    private var requestQueue = Queue<URLRequest>()

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

    private func sendRequest(_ request: URLRequest, uuid: String = UUID().uuidString) {
        let task = URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .retry(NewsParser.config!.requestAttemptsCount)
            .decode(type: NewsNode.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .replaceError(with: NewsNode.zero)
            .eraseToAnyPublisher()
            .sink(receiveValue: {
                [unowned self] result in
                defer {
                    self.runningTasks.removeValue(forKey: uuid)
                    if let request = self.requestQueue.dequeue() {
                        sendRequest(request)
                    }
                }
                guard let news = result.news, !news.isEmpty else {
                    self.newsUpdatedPub.send([])
                    return
                }
                
                var ids = [UInt]()
                for newsItem in news {
                    NewsStorage.shared.addNewsItem(newsItem)
                    ids.append(newsItem.id)
                }
                easyLog("data received")
                self.newsUpdatedPub.send(ids)
            })
        self.runningTasks[uuid] = task
    }

    func requestNews(page: UInt = 1, count: UInt) {
        easyLog("page = \(page); count = \(count)")
        let endpoint = self.newsEndpoint!
            .appending(path: String(page))
            .appending(path: String(count))

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = NewsParser.config!.requestTimeoutSec

        if self.runningTasks.isEmpty {
            sendRequest(request)
        } else {
            self.requestQueue.enqueue(request)
        }
    }
}
