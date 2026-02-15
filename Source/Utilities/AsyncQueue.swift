//
//  AsyncQueue.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/15/26.
//

import Foundation

class AsyncOperationQueue {
    private var continuation: AsyncStream<() async -> Void>.Continuation?

    init() {
        let stream = AsyncStream<() async -> Void> {
            self.continuation = $0
        }
        
        Task {
            for await operation in stream {
                await operation()
            }
        }
    }

    public func enqueue(_ operation: @escaping () async -> Void) {
        self.continuation?.yield(operation)
    }

    deinit {
        self.continuation?.finish()
    }
}
