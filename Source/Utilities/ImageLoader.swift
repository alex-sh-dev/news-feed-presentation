//
//  ImageLoader.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import UIKit

public class ImageLoader {
    public static let shared = ImageLoader()
    
    typealias AnyItem = Any
    typealias LoadCompletion = (_ item: AnyItem, _ image: UIImage?, _ cached: Bool) -> Void
    typealias LoadCompletionItemPair = (LoadCompletion, AnyItem)

    private var loadingResponses: [URL: [LoadCompletionItemPair]] = [:]
    private let lock = NSLock()

    private init() {}

    final func load(url: URL, item: AnyItem, beforeLoad: @escaping () -> Void = {},
                    completion: @escaping LoadCompletion) {
        if let cachedImage = URLCache.image(for: url) {
            completion(item, cachedImage, true)
            return
        }
        
        self.lock.with {
            if loadingResponses[url] != nil {
                loadingResponses[url]?.append((completion, item))
                return
            } else {
                loadingResponses[url] = [(completion, item)]
            }
        }
        
        beforeLoad()
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            var existLoadCompletions: Bool = false
            self.lock.with { existLoadCompletions = self.loadingResponses[url] != nil }
            guard let responseData = data, let image = UIImage(data: responseData),
                  existLoadCompletions, error == nil else {
                DispatchQueue.main.async {
                    completion(item, nil, false)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.lock.with {
                    if let loadCompletions = self.loadingResponses[url] {
                        URLCache.storeImage(image, for: url)
                        for (loadCompletion, savedItem) in loadCompletions {
                            loadCompletion(savedItem, image, false)
                        }
                        self.loadingResponses.removeValue(forKey: url)
                    }
                }
            }
        }.resume()
    }
}
