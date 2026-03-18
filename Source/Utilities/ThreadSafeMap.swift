//
//  ThreadSafeMap.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/18/26.
//

import Foundation

class ThreadSafeMap<Key: Hashable, Value> {
    private var map: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "" , attributes: .concurrent)

    func value(forKey key: Key) -> Value? {
        var result: Value?
        self.queue.sync {
            result = self.map[key]
        }
        return result
    }

    func setValue(_ value: Value, forKey key: Key) {
        self.queue.async(flags: .barrier) {
            self.map[key] = value
        }
    }

    func removeValue(forKey key: Key) {
        self.queue.async(flags: .barrier) {
            self.map.removeValue(forKey: key)
        }
    }

    func containsKey(_ key: Key) -> Bool {
        var contains = false
        self.queue.sync {
            contains = self.map.keys.contains(key)
        }
        return contains
    }

    func forEach(_ body: @escaping (Key, Value) -> Void) {
        self.queue.sync {
            self.map.forEach(body)
        }
    }

    func updateForEach(_ body: @escaping (Key, Value) -> Void) {
        self.queue.async(flags: .barrier) {
            self.map.forEach(body)
        }
    }

    func updateValue(forKey key: Key, _ block: @escaping (Value) -> Void) {
        self.queue.async(flags: .barrier) {
            if let value = self.map[key] {
                block(value)
            }
        }
    }

    var keys: [Key] {
        var keys: [Key]!
        self.queue.sync {
            keys = Array(self.map.keys)
        }
        return keys
    }

    var count: Int {
        var count = 0
        self.queue.sync {
            count = self.map.count
        }
        return count
    }

    var isEmpty: Bool {
        var isEmpty = true
        self.queue.sync {
            isEmpty = self.map.isEmpty
        }
        return isEmpty
    }
}
