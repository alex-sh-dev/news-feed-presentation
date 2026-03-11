//
//  URLCache.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

extension URLCache {
    static func image(for url: URL) -> UIImage? {
        let urlReq = URLRequest(url: url)
        guard let cachedResponse = URLCache.shared.cachedResponse(for: urlReq) else {
            return nil
        }
        
        return UIImage(data: cachedResponse.data) ?? nil
    }

    static func storeImage(_ image: UIImage, for url: URL) {
        let urlReq = URLRequest(url: url)
        let urlResp = URLResponse(url: url, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        
        let cachedResp = CachedURLResponse(response: urlResp, data: image.pngData()!, storagePolicy: .allowed)
        URLCache.shared.storeCachedResponse(cachedResp, for: urlReq)
    }
}
