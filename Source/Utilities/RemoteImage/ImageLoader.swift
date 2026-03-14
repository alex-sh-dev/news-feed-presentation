//
//  ImageLoader.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import UIKit

public class ImageLoader {
    static let shared = ImageLoader()

    typealias LoadCompletion = (_ url: URL, _ image: UIImage?, _ cached: Bool) -> Void

    private var loadingResponses: [URL: [LoadCompletion]] = [:]
    private var tasks: [URL: URLSessionDataTask] = [:]

    private init() {}

    final func suspendTasks(for urls: [URL]) {
        let surls = Set(urls)
        for (url, task) in self.tasks {
            if surls.contains(url) {
                task.suspend()
                continue
            }

            if task.state == .suspended {
                task.resume()
            }
        }
    }

    final func resumeTasksIfNeeded(for urls: [URL]) {
        let surls = Set(urls)
        for (url, task) in self.tasks {
            if surls.contains(url) && task.state == .suspended {
                task.resume()
            }
        }
    }

    final func cancelAllTasks() {
        for (_, task) in self.tasks {
            task.cancel()
        }
    }

    private func iterateLoadCompletions(image: UIImage?, url: URL) {
        DispatchQueue.main.async {
            if let loadCompletions = self.loadingResponses[url] {
                if let image = image {
                    URLCache.storeImage(image, for: url)
                }
                for completion in loadCompletions {
                    completion(url, image, false)
                }
                self.loadingResponses.removeValue(forKey: url)
                self.tasks.removeValue(forKey: url)
            }
        }
    }

    final func loadIfNeeded(url: URL) {
        if !URLCache.existImage(for: url) {
            self.load(url: url)
        }
    }

    final func load(url: URL, beforeLoad: @escaping () -> Void = {},
                    completion: @escaping LoadCompletion = { _,_,_ in }) {
        if let cachedImage = URLCache.image(for: url) {
            completion(url, cachedImage, true)
            return
        }

        beforeLoad()

        if self.loadingResponses[url] != nil {
            self.loadingResponses[url]?.append(completion)
            self.resumeTasksIfNeeded(for: [url])
            return
        } else {
            self.loadingResponses[url] = [completion]
        }

        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
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
