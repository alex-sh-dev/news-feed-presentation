//
//  NewsStorage.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import Foundation

extension NSLock { //?? move to sp file
    @discardableResult
    func with<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try block()
    }
}

class NewsStorage {
    static let shared = NewsStorage()
    
    let lock = NSLock()
    var news = [UInt: NewsItem]()
    
    private init() {}
}
