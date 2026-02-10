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
    }
    
    private static var config: Config?
    var baseEndpoint: URL
    let idsPub = PassthroughSubject<[UInt], Never>() //?? rename?
    
    private init() {
        guard let config = NewsParser.config else {
            fatalError("Error: you must call setup before accessing NewsParser.shared")
        }
        
        self.baseEndpoint = config.baseEndpoint
    }
    
    class func setup(_ config: Config) {
        NewsParser.config = config
    }
    
    func sendRequest(page: UInt, count: UInt) {
        //?? page * count <= totalCount
        
        let endpoint = self.baseEndpoint
            .appending(path: String(page))
            .appending(path: String(count))
        
        
        URLSession.shared.dataTask(with: endpoint) {
            [unowned self] (data, response, error) -> Void in
            
            if error == nil && data != nil {
                do {
                    let result = try JSONDecoder().decode(NewsNode.self, from: data!)
                    guard let news = result.news else {
                        //publish error? //??
                        return //??
                    }
                    
                    var ids = [UInt]()
                    for newsItem in news {
                        NewsStorage.shared.lock.with {
                            NewsStorage.shared.news[newsItem.id] = newsItem
                        }
                        ids.append(newsItem.id)
                    }
                    self.idsPub.send(ids)
                } catch {
                    //publish error? //??
                    print(error) //??
                }
            } else {
                //publish error? //??
            }
        }.resume()
    }
}
