//
//  NewsItemImagesCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/12/26.
//

import UIKit

class NewsItemImagesCell: UICollectionViewCell {
    private enum Section {
        case main
    }

    var imageUrls: [URL] = [] {
        didSet {
            var snapshot = self.dataSource.snapshot()
            if snapshot.itemIdentifiers == imageUrls {
                return
            }

            snapshot.deleteAllItems()
            snapshot.appendSections([.main])
            snapshot.appendItems(imageUrls)
            self.dataSource.apply(snapshot, animatingDifferences: false) {
                [weak self] in
                guard let self = self, !self.imageUrls.isEmpty else { return }
                let firstIndexPath = IndexPath(row: 0, section: 0)
                self.imageCollection.scrollToItem(at: firstIndexPath, at: .left, animated: false)
            }
        }
    }

    var visibleImageUrls: [URL] {
        get {
            let visibleIndexPaths = self.imageCollection.indexPathsForVisibleItems
            var urls: [URL] = []
            for indexPath in visibleIndexPaths {
                if let url = self.dataSource.itemIdentifier(for: indexPath) {
                    urls.append(url)
                }
            }
            return urls
        }
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, URL>!
    
    @IBOutlet weak var imageCollection: UICollectionView! {
        didSet {
            self.imageCollection.collectionViewLayout = ImagesCompositionalLayout {
                [unowned self] in
                return self.imageUrls.count > 1
            }

            let newsItemImageCellRegistration = UICollectionView.CellRegistration<NewsItemImageCell, URL> {
                cell, _, url in
                cell.configure(with: url)
            }

            self.dataSource = UICollectionViewDiffableDataSource<Section, URL>(collectionView: self.imageCollection) {
                (collectionView: UICollectionView, indexPath: IndexPath, item: URL) -> UICollectionViewCell? in
                return collectionView.dequeueConfiguredReusableCell(
                    using: newsItemImageCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
            
            var snapshot = NSDiffableDataSourceSnapshot<Section, URL>()
            snapshot.appendSections([.main])
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}
