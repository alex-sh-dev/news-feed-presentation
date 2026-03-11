//
//  Lock.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import Foundation

extension NSLock {
    @discardableResult
    func with<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try block()
    }
}
