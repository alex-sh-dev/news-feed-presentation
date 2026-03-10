//
//  ImageLoader.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import UIKit

public class ImageLoader {
    static let shared = ImageLoader()

    typealias AnyItem = Any
    typealias LoadCompletion = (_ item: AnyItem, _ image: UIImage?, _ cached: Bool) -> Void
    typealias LoadCompletionItemPair = (LoadCompletion, AnyItem)

    private var loadingResponses: [URL: [LoadCompletionItemPair]] = [:]
    private var tasks: [URL: URLSessionDataTask] = [:]
    private let lock = NSLock()

    private init() {}

    final func suspendTasks(for urls: [URL]) {
        for (url, task) in self.tasks {
            if urls.contains(url) {
                task.suspend()
                continue
            }

            if task.state == .suspended {
                task.resume()
            }
        }
    }

    final func resumeTasksIfNeeded(for urls: [URL]) {
        for (url, task) in self.tasks {
            if urls.contains(url) && task.state == .suspended {
                task.resume()
            }
        }
    }

    private func iterateLoadCompletions(image: UIImage?, url: URL) {
        DispatchQueue.main.async {
            self.lock.lock()
            defer {
                self.lock.unlock()
            }
            if let loadCompletions = self.loadingResponses[url] {
                if let image = image {
                    URLCache.storeImage(image, for: url)
                }
                for (loadCompletion, savedItem) in loadCompletions {
                    loadCompletion(savedItem, image, false)
                }
                self.loadingResponses.removeValue(forKey: url)
                self.tasks.removeValue(forKey: url)
            }
        }
    }

    final func load(url: URL, item: AnyItem, beforeLoad: @escaping () -> Void = {},
                    completion: @escaping LoadCompletion) {
        if let cachedImage = URLCache.image(for: url) {
            completion(item, cachedImage, true)
            return
        }
        
        self.lock.with {
            if self.loadingResponses[url] != nil {
                self.loadingResponses[url]?.append((completion, item))
                self.resumeTasksIfNeeded(for: [url])
                return
            } else {
                self.loadingResponses[url] = [(completion, item)]
            }
        }

        beforeLoad()

        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            var existLoadCompletions: Bool = false
            self.lock.with { existLoadCompletions = self.loadingResponses[url] != nil }
            if !existLoadCompletions {
                return
            }

            guard let responseData = data,
                  let image = UIImage(data: responseData), error == nil else {
                self.iterateLoadCompletions(image: nil, url: url)
                return
            }

            self.iterateLoadCompletions(image: image, url: url)
        }

        task.resume()
        self.tasks[url] = task
    }
}
