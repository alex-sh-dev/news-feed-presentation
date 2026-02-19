//
//  NewsItemParseTask.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/19/26.
//

import Foundation

class NewsItemParseTask {
    private struct Consts {
        static let kObjRepCharSymbol = "\u{fffc}"
    }

    private(set) var texts: [String] = []
    private(set) var imageUrls: [URL] = []
    
    private let text: String!
    private let titleImageUrl: URL?
    let id: UInt!
    
    init(text: String, titleImageUrl: URL?, for id: UInt) {
        self.text = text
        self.titleImageUrl = titleImageUrl
        self.id = id
    }
    
    var finalText: String {
        if self.texts.isEmpty {
            return ""
        }

        var finalText = self.texts.joined()
        finalText = finalText.replacingOccurrences(
            of: Consts.kObjRepCharSymbol, with: "")
        while finalText.last == "\n" {
            finalText.removeLast()
        }
        finalText = finalText.replacingOccurrences(
            of: "\\n+", with: "\n\n",
            options: .regularExpression, range: nil
        )

        return finalText
    }
    
    var finalImageUrls: [URL]? {
        if self.imageUrls.isEmpty {
            return nil
        }
        
        if let url = self.titleImageUrl {
            self.imageUrls.removeAll { $0 == url }
            return self.imageUrls
        }

        return nil
    }
    
    func start() {
        guard let data = self.text.data(using: String.Encoding.utf16,
                                   allowLossyConversion: false) else {
            return
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html]
        guard let attrString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            return
        }
        
        attrString.enumerateAttributes(in: NSRange(location: 0, length: attrString.length), options: []) {
            (attributes, range, stop) in
            let substring = (attrString.string as NSString).substring(with: range)
            let isPresent = !substring.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if isPresent && (attributes[.link] == nil || attributes[.attachment] == nil) {
                self.texts.append(substring)
            }
        }
            
        attrString.enumerateAttribute(.link, in: NSRange(location: 0, length: attrString.length), options: []) {
            (value, range, stop) in
            if let url = value as? URL,
               !url.pathExtension.isEmpty {
                imageUrls.append(url)
            }
        }
    }
}
