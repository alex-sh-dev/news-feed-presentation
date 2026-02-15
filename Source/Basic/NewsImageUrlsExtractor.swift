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
    
    let imageUrlsUpdatedPublisher = PassthroughSubject<UInt, Never>()
    
    private let operationQueue = AsyncOperationQueue()
    
    private init() {}
    
    struct Consts {
        static let kFileNameSeparator = "_"
        static let kFileNameMaxSplits = 2
        static let kMaxTaskCount = 30
        static let kStartPoint = 1
    }
    
    private func extract(for url: URL) async throws -> [URL]? {
        let ext = url.pathExtension
        if ext.isEmpty {
            return nil
        }

        let fileName = url.deletingPathExtension().lastPathComponent
        
        var cmps: [String] = fileName.components(separatedBy: Consts.kFileNameSeparator)
        if cmps.count < Consts.kFileNameMaxSplits {
            return nil
        }
        
        guard var number = UInt(cmps.last!),
              number <= Consts.kStartPoint  else {
            return nil
        }
        
        cmps = Array(cmps.dropLast())
        var name = cmps.first
        if cmps.count > 1 {
            name = cmps.joined(separator: Consts.kFileNameSeparator)
        }

        number += 1
        let basePath = url.deletingLastPathComponent()
        
        var resUrls = [URL]()
        while true {
            let newFileName = name! + Consts.kFileNameSeparator + String(number) + ".\(ext)"
            let newUrl = basePath.appending(path: newFileName)
            
            var request = URLRequest(url: newUrl)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 1.0
            
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
            if number > Consts.kMaxTaskCount {
                break
            }
        }
        
        return resUrls
    }
    
    func addTask(for url: URL?, with id: UInt?) {
        if url == nil || id == nil {
            return
        }
        
        self.operationQueue.enqueue {
            do {
                if let urls = try await self.extract(for: url!) {
                    NewsStorage.shared.lock.with {
                        NewsStorage.shared.imageUrls[id!] = urls
                    }
                    self.imageUrlsUpdatedPublisher.send(id!)
                }
            } catch {}
        }
    }
}
