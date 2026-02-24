//
//  NewsItemParseTask.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/19/26.
//

import Foundation

class NewsItemParseTask: NSObject, XMLParserDelegate {
    private struct Constants {
        static let kObjRepCharSymbol = "\u{fffc}"
        static let kCDivNode = "cdiv"
        static let kImageNode = "img"
        static let kImageSourceAttrName = "src"
    }
    
    private(set) var texts: [String] = []
    private(set) var imageUrls: [URL] = []
    
    private let titleImageUrl: URL?
    let id: UInt!
    
    private var xmlParser: XMLParser!
    
    private var curNode = ""
    private var startElementUpdated = false
    private var curText = ""
    
    init(text: String, titleImageUrl: URL?, for id: UInt) {
        self.titleImageUrl = titleImageUrl
        self.id = id
        super.init()
        self.xmlParser = XMLParser(data: self.preparedData(text))
        self.xmlParser.delegate = self
    }
    
    private func preparedData(_ rawText: String) -> Data {
        var text = rawText
        text.insert(contentsOf: "<\(Constants.kCDivNode)>",
                    at: text.startIndex)
        text.replace("\\\"", with: "'")
        text.replace(/&[^;]+;/, with: "")
        text.replace("\r\n\t", with:"\n")
        text.replace("\r\n", with: "\n")
        text.replace("<br />", with: "\n")
        text.append("</\(Constants.kCDivNode)>")
        return text.data(using: .utf8) ?? Data()
    }
    
    var finalText: String {
        if self.texts.isEmpty {
            return ""
        }
        
        var finalText = self.texts.joined()
        finalText = finalText.replacingOccurrences(
            of: Constants.kObjRepCharSymbol, with: "")
        finalText.replace(/\ +/, with: " ")
        finalText.replace(/\n\ /, with: "\n")
        finalText.replace(/\n+/, with: "\n\n")
        while finalText.first == "\n" {
            finalText.removeFirst()
        }
        while finalText.last == "\n" {
            finalText.removeLast()
        }
        
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
        self.xmlParser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        self.curNode = elementName
        if elementName == Constants.kImageNode {
            if let src = attributeDict[Constants.kImageSourceAttrName],
               let url = URL(string: src),
                !url.pathExtension.isEmpty {
                self.imageUrls.append(url)
            }
        }
        self.startElementUpdated = true
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.startElementUpdated {
            if !self.curText.isEmpty {
                self.texts.append(self.curText)
                self.curText = ""
            }
        }
        self.curText.append(string)
        self.startElementUpdated = false
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == Constants.kCDivNode && !self.curText.isEmpty {
            self.texts.append(self.curText)
        }
        self.startElementUpdated = false
    }
}
