//
//  AppDelegate.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private struct Conf {
        static let kMemoryCapacityMb = 40 * 1024 * 1024
        static let kDiskCapacityMb = 500 * 1024 * 1024
        static let kDiskPath = "urlcache"
        static let kNewsEndpoint = "https://webapi.autodoc.ru/api/news"
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let urlCache = URLCache(memoryCapacity: Conf.kMemoryCapacityMb, diskCapacity: Conf.kDiskCapacityMb , diskPath: Conf.kDiskPath)
        URLCache.shared = urlCache
        
        // TODO: add cache clenup (Settings)
        // urlCache.removeAllCachedResponses()
        
        let endpoint = URL(string: Conf.kNewsEndpoint)
        NewsParser.setup(NewsParser.Config(baseEndpoint: endpoint!))
        
        return true
    }
}
