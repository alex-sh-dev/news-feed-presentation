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
        config.title = item.value.title
        config.subtitle = item.value.description
        config.imageUrl = item.value.titleImageUrl
        config.date = item.value.publishedDate
        self.contentConfiguration = config
    }
}
