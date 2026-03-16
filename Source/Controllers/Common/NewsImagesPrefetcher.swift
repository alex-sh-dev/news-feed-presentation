//
//  NewsImagesPrefetcher.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/15/26.
//

import UIKit

class NewsImagesPrefetcher: NSObject, UICollectionViewDataSourcePrefetching {
    typealias ItemIdProvider = (_ indexPath: IndexPath) -> UInt?

    private(set) var model: BaseNewsViewModel!
    private(set) var itemIdProvider: ItemIdProvider? = nil

    init(model: BaseNewsViewModel, itemIdProvider: @escaping ItemIdProvider) {
        self.model = model
        self.itemIdProvider = itemIdProvider
    }

    deinit {
        ImageLoader.shared.cancelAllTasks()
    }

    private func newsItem(for indexPath: IndexPath) -> NewsItem? {
        guard let id = self.itemIdProvider?(indexPath) else {
            return nil
        }
        return self.model.newsItem(at: id)
    }

    private func imageUrl(for indexPath: IndexPath) -> URL? {
        if let newsItem = self.newsItem(for: indexPath),
           let url = newsItem.titleImageUrl {
            return url
        }
        return nil
    }

    private func imageUrls(for indexPaths: [IndexPath]) -> [URL] {
        var urls: [URL] = []
        for indexPath in indexPaths {
            if let url = self.imageUrl(for: indexPath) {
                urls.append(url)
            }
        }
        return urls
    }

    private func loadImage(for indexPath: IndexPath) {
        guard let url = self.imageUrl(for: indexPath) else {
            return
        }

        ImageLoader.shared.loadIfNeeded(url: url)
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            self.loadImage(for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        ImageLoader.shared.cancelTasks(for: self.imageUrls(for: indexPaths))
    }
}
