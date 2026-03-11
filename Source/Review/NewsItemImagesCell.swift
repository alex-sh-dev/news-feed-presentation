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
    
    private enum ImageIdentifier: Hashable {
        case value(String)
        
        static var generated: ImageIdentifier {
            let uuid = UUID().uuidString
            return .value(uuid)
        }
    }

    private var imageUrlMap: [ImageIdentifier: URL] = [:]
    var imageUrls: [URL] = [] {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.imageUrlMap.removeAll()
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteAllItems()
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            
            DispatchQueue.main.async { [unowned self] in
                var snapshot = self.dataSource.snapshot()
                snapshot.appendSections([.main])
                var identifiers: [ImageIdentifier] = []
                for url in self.imageUrls {
                    let uuid = ImageIdentifier.generated
                    self.imageUrlMap[uuid] = url
                    identifiers.append(uuid)
                }
                snapshot.appendItems(identifiers)
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    var visibleImageUrls: [URL] {
        get {
            let identifiers = self.visibleItemIdentifiers()
            var urls: [URL] = []
            for idfr in identifiers {
                guard let url = self.imageUrlMap[idfr] else {
                    continue
                }
                urls.append(url)
            }

            return urls
        }
    }

    private func visibleItemIdentifiers() -> [ImageIdentifier] {
        let visibleIndexPaths = self.imageCollection.indexPathsForVisibleItems
        var visibleIdentifiers: [ImageIdentifier] = []
        for indexPath in visibleIndexPaths {
            if let idfr = self.dataSource.itemIdentifier(for: indexPath) {
                visibleIdentifiers.append(idfr)
            }
        }
        return visibleIdentifiers
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, ImageIdentifier>!
    
    @IBOutlet weak var imageCollection: UICollectionView! {
        didSet {
            self.imageCollection.collectionViewLayout = ImagesCompositionalLayout {
                [unowned self] in
                return self.imageUrls.count > 1
            }

            let newsItemImageCellRegistration = UICollectionView.CellRegistration<NewsItemImageCell, URL> {
                cell, _, item in
                cell.configure(with: item)
            }

            self.dataSource = UICollectionViewDiffableDataSource<Section, ImageIdentifier>(collectionView: self.imageCollection) { [unowned self]
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: ImageIdentifier) -> UICollectionViewCell? in
                let imageUrl = self.imageUrlMap[identifier]
                return collectionView.dequeueConfiguredReusableCell(
                    using: newsItemImageCellRegistration,
                    for: indexPath,
                    item: imageUrl
                )
            }
            
            var snapshot = NSDiffableDataSourceSnapshot<Section, ImageIdentifier>()
            snapshot.appendSections([.main])
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}
