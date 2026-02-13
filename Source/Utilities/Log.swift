//
//  Log.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/13/26.
//

import Foundation

func easyLog(_ text: String = "", funcName: String = #function) {
#if DEBUG
    print(funcName)
    if !text.isEmpty {
        print(text)
    }
#endif
}
