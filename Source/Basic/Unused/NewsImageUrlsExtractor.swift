//
//  NewsImageUrlsExtractor.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/14/26.
//

import Foundation
import Combine

class NewsImageUrlsExtractor {
    static let shared = NewsImageUrlsExtractor()
    
    let imageUrlsUpdatedPub = PassthroughSubject<UInt, Never>()
    
    private let operationQueue = AsyncOperationQueue()
    
    private init() {}
    
    struct Constants {
        static let kFileNameSeparator = "_"
        static let kFileNameMaxSplits = 2
        static let kMaxTaskCount = 30
        static let kStartPoint = 1
        static let kSendRequestDelayMs: UInt64 = 30
    }
    
    private func extract(for url: URL) async throws -> [URL]? {
        let ext = url.pathExtension
        if ext.isEmpty {
            return nil
        }

        let fileName = url.deletingPathExtension().lastPathComponent
        
        var cmps: [String] = fileName.components(separatedBy: Constants.kFileNameSeparator)
        if cmps.count < Constants.kFileNameMaxSplits {
            return nil
        }
        
        guard var number = UInt(cmps.last!),
              number <= Constants.kStartPoint  else {
            return nil
        }
        
        cmps = Array(cmps.dropLast())
        var name = cmps.first
        if cmps.count > 1 {
            name = cmps.joined(separator: Constants.kFileNameSeparator)
        }

        number += 1
        let basePath = url.deletingLastPathComponent()
        
        var resUrls = [URL]()
        while true {
            let newFileName = name! + Constants.kFileNameSeparator + String(number) + ".\(ext)"
            let newUrl = basePath.appending(path: newFileName)
            
            var request = URLRequest(url: newUrl)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 1.0
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let hasStausCode200 = try await withThrowingTaskGroup(of: (Data, URLResponse).self, returning: Bool.self) {
                group in
                var hasStausCode200 = false
                
                let req = request
                group.addTask {
                    try await URLSession.shared.data(for: req)
                }
                
                for try await (_, response) in group {
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continue
                    }

                    hasStausCode200 = httpResponse.statusCode == 200
                }
                
                return hasStausCode200
            }
            
            if !hasStausCode200 {
                break
            } else {
                resUrls.append(newUrl)
            }
            
            number += 1
            if number > Constants.kMaxTaskCount {
                break
            }
            
            try await Task.sleep(nanoseconds: Constants.kSendRequestDelayMs * NSEC_PER_MSEC)
        }
        
        return resUrls
    }
    
    func addTask(for url: URL?, with id: UInt?) {
        if url == nil || id == nil {
            return
        }
        
        self.operationQueue.enqueue { [weak self] in
            do {
                if let urls = try await self?.extract(for: url!) {
                    NewsStorage.shared.lock.with {
                        NewsStorage.shared.imageUrls[id!] = urls
                    }
                    self?.imageUrlsUpdatedPub.send(id!)
                }
            } catch {}
        }
    }
}
