//
//  Queue.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/10/26.
//

import Foundation

struct Queue<Element: Equatable> {
    private var items: [Element] = []

    mutating func enqueue(_ item: Element, checkDuplicate: Bool = true) {
        if checkDuplicate && self.items.contains(item) {
            return
        }

        self.items.append(item)
    }

    mutating func dequeue() -> Element? {
        if self.items.isEmpty {
            return nil
        }

        return self.items.removeFirst()
    }

    func peek() -> Element? {
        return self.items.first
    }

    var isEmpty: Bool {
        return self.items.isEmpty
    }
}
