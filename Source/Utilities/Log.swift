//
//  Log.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/13/26.
//

import Foundation

func easyLog(_ text: String = "", funcName: String = #function) {
#if DEBUG
    var str = funcName
    if !text.isEmpty {
        str += ": \(text)"
    }
    print(str)
#endif
}
