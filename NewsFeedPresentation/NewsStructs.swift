//
//  NewsStructs.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/10/26.
//

import Foundation

struct NewsNode: Decodable {
    let news: [NewsItem]?
    let totalCount: UInt?
    
    enum CodingKeys: String, CodingKey {
        case news
        case totalCount
    }
}

struct NewsItem: Decodable {
    var id: UInt!
    var title: String?
    var description: String?
    var publishedDate: Date?
    var url: URL?
    var fullUrl: URL?
    var titleImageUrl: URL?
    var categoryType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case publishedDate
        case url, fullUrl, titleImageUrl
        case categoryType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UInt.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let dateStr = try container.decodeIfPresent(String.self, forKey: .publishedDate) ?? ""
        self.publishedDate = dateFormatter.date(from: dateStr)
        
        let urlStr = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.url = URL(string: urlStr)
        let fullUrlStr = try container.decodeIfPresent(String.self, forKey: .fullUrl) ?? ""
        self.fullUrl = URL(string: fullUrlStr)
        let titleImageUrlStr = try container.decodeIfPresent(String.self, forKey: .titleImageUrl) ?? ""
        self.titleImageUrl = URL(string: titleImageUrlStr)
        self.categoryType = try container.decodeIfPresent(String.self, forKey: .categoryType)
    }
}
