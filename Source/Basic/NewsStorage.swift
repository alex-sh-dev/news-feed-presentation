//
//  NewsStorage.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import Foundation

class NewsStorage {
    static let shared = NewsStorage()
    
    let lock = NSLock()
    var news = [UInt: NewsItem]()
    var images = [UInt: [URL]]()
    
    private init() {}
}
