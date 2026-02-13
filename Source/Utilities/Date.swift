//
//  Date.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/13/26.
//

import Foundation

extension Date {
    func relativeDate(timeStyle: DateFormatter.Style = .none,
                      dateStyle: DateFormatter.Style = .full) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = timeStyle
        relativeDateFormatter.dateStyle = dateStyle
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter.string(from: self)
    }
}
