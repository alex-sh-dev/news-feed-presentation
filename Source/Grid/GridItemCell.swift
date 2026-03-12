//
//  GridItemCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit

class GridItemCell: PreviewNewsItemCell {
    func configure(item: NewsItem) {
        var config = GridItemContentConfiguration()
        config.title = item.title
        config.subtitle = item.description
        config.imageUrl = item.titleImageUrl
        config.date = item.publishedDate
        self.contentConfiguration = config
    }
}
