//
//  ImageCache.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import UIKit

extension URLCache { //?? move to sp file
    //?? safe thread?
    static func image(for url: URL) -> UIImage? {
        let urlReq = URLRequest(url: url)
        guard let cachedResponse = URLCache.shared.cachedResponse(for: urlReq) else {
            return nil
        }
        
        return UIImage(data: cachedResponse.data) ?? nil
    }

    //?? safe thread?
    static func storeImage(_ image: UIImage, for url: URL) {
        let urlReq = URLRequest(url: url)
        let urlResp = URLResponse(url: url, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        
        let cachedResp = CachedURLResponse(response: urlResp, data: image.pngData()!, storagePolicy: .allowed)
        URLCache.shared.storeCachedResponse(cachedResp, for: urlReq)
    }
}

public class ImageCache {
    public static let publicCache = ImageCache() //?? -> shared
    private var loadingResponses: [URL: [(NewsItem, UIImage?, Bool) -> Void]] = [:] //?? remove after use? //?? thread safe?

    private init() {}

    final func load(url: URL, item: NewsItem, completion: @escaping (_ item: NewsItem, _ image: UIImage?, _ cached: Bool) -> Void) {
        
        //?? if image on server will be changed? last modified?
        
        if let cachedImage = URLCache.image(for: url) {
//            DispatchQueue.main.async { //??
                completion(item, cachedImage, true)
//            }
            return
        }
        
        if loadingResponses[url] != nil {
            loadingResponses[url]?.append(completion)
            return
        } else {
            loadingResponses[url] = [completion]
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let responseData = data, let image = UIImage(data: responseData),
                  let blocks = self.loadingResponses[url], error == nil else {
                DispatchQueue.main.async {
                    completion(item, nil, false)
                }
                return
            }
            
            DispatchQueue.main.async { //??
                URLCache.storeImage(image, for: url)
            }
            
            for block in blocks {
                DispatchQueue.main.async {
                    block(item, image, false)
                    //?? remove from list
                }
                return
            }
        }.resume()
    }
}
