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
        let formatter = DateFormatter()
        formatter.timeStyle = timeStyle
        formatter.dateStyle = dateStyle
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: self)
    }
}
