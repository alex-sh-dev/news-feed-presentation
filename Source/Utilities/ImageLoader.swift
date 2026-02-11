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

    private var loadingResponses: [URL: LoadCompletion] = [:]
    private let lock = NSLock()

    private init() {}

    final func load(url: URL, item: AnyItem, beforeLoad: @escaping () -> Void = {},
                    completion: @escaping LoadCompletion) {
        if let cachedImage = URLCache.image(for: url) {
            completion(item, cachedImage, true)
            return
        }
        
        self.lock.with { self.loadingResponses[url] = completion }
        
        beforeLoad()
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            var loadCompletion: LoadCompletion?
            self.lock.with { loadCompletion = self.loadingResponses[url] }
            guard let responseData = data, let image = UIImage(data: responseData),
                  loadCompletion != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(item, nil, false)
                }
                return
            }
            
            DispatchQueue.main.async {
                URLCache.storeImage(image, for: url)
                loadCompletion!(item, image, false)
                self.lock.with { self.loadingResponses.removeValue(forKey: url) }
            }
        }.resume()
    }
}
