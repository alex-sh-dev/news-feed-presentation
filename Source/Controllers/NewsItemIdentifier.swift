//
//  NewsItemIdentifier.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation

public enum NewsItemIdentifier: Hashable {
    case notValid
    case value(UInt)
    case index(UInt)
    
    var rawValue: UInt {
        get {
            switch self {
            case .notValid:
                return 0
            case .value(let val):
                return val
            case .index(let ind):
                return ind
            }
        }
    }
}
