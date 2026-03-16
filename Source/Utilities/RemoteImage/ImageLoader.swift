//
//  ImageLoader.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import UIKit

public class ImageLoader {
    private struct Constants {
        static let kRequestTimeoutSec: TimeInterval = 5
    }

    static let shared = ImageLoader()

    typealias LoadCompletion = (_ url: URL, _ image: UIImage?) -> Void

    private var loadingResponses: [URL: [LoadCompletion]] = [:]
    private var tasks: [URL: URLSessionDataTask] = [:]

    private init() {}

    final func cancelTasks(for urls: [URL]) {
        let surls = Set(urls)
        for (url, task) in self.tasks {
            if surls.contains(url) {
                task.cancel()
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
                self.loadingResponses.removeValue(forKey: url)
                self.tasks.removeValue(forKey: url)

                if let image = image {
                    URLCache.storeImage(image, for: url)
                }
                for completion in loadCompletions {
                    completion(url, image)
                }
            }
        }
    }

    final func needLoad(url: URL) -> Bool {
        return !URLCache.existImage(for: url)
    }

    final func loadIfNeeded(url: URL, completion: @escaping LoadCompletion = { _,_ in }) {
        if self.needLoad(url: url) {
            self.load(url: url, completion: completion)
        }
    }

    final func load(url: URL, beforeLoad: @escaping () -> Void = {},
                    completion: @escaping LoadCompletion = { _,_ in }) {
        if let cachedImage = URLCache.image(for: url) {
            completion(url, cachedImage)
            return
        }

        beforeLoad()

        if self.loadingResponses[url] != nil {
            self.loadingResponses[url]?.append(completion)
            return
        } else {
            self.loadingResponses[url] = [completion]
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Constants.kRequestTimeoutSec

        // TODO: refactor using serial queue (improves load efficiency, simplifies cancellation)
        let task = URLSession.shared.dataTask(with: request) {
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
