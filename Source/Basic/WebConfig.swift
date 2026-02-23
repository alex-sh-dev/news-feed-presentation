//
//  WebConfig.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/23/26.
//

import Foundation

struct WebConfig {
    var newsEndpoint: URL?
    var newsItemEndpoint: URL?
    let requestAttemptsCount = 3
    let sendRequestDelayMs: UInt64 = 500
    
    init() {}
}

