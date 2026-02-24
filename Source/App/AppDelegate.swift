//
//  AppDelegate.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private struct Config {
        static let kMemoryCapacityMb = 40 * 1024 * 1024
        static let kDiskCapacityMb = 500 * 1024 * 1024
        static let kDiskPath = "urlcache"
        static let kBaseEndpoint = "https://webapi.autodoc.ru/api"
        static let KNewsEndpointPostfix = "news"
        static let kNewsItemEndpointPostfix = "item"
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        URLCache.shared = URLCache(memoryCapacity: Config.kMemoryCapacityMb,
                                   diskCapacity: Config.kDiskCapacityMb ,
                                   diskPath: Config.kDiskPath)
        
        // TODO: add cache clenup (Settings)
        // urlCache.removeAllCachedResponses()
        
        var config = WebConfig()
        config.newsEndpoint = URL(string: Config.kBaseEndpoint)?
            .appending(path: Config.KNewsEndpointPostfix)
        config.newsItemEndpoint = URL(string: Config.kBaseEndpoint)?
            .appending(path: Config.KNewsEndpointPostfix)
            .appending(path: Config.kNewsItemEndpointPostfix)
        NewsParser.setup(config)
        
        return true
    }
}
