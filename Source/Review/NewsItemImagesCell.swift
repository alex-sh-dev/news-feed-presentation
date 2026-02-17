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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.imageUrlMap.removeAll()
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteAllItems()
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
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
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, ImageIdentifier>!
    
    @IBOutlet weak var imageCollection: UICollectionView! {
        didSet {
            self.imageCollection.collectionViewLayout = ImagesCompositionalLayout {
                [weak self] in
                let count = self?.imageUrls.count ?? 0
                return count > 1
            }
            
            self.dataSource = UICollectionViewDiffableDataSource<Section, ImageIdentifier>(collectionView: self.imageCollection) { [weak self]
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: ImageIdentifier) -> UICollectionViewCell? in
                
                guard let self = self else { return nil }
                
                let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemImageCell.self)
                
                guard let imageUrl = self.imageUrlMap[identifier] else {
                    return cell
                }
                
                ImageLoader.shared.load(url: imageUrl, item: identifier, beforeLoad: {
                    [weak cell] in
                    cell?.setDefaultImage()
                }) { [weak self, weak cell]
                    (fetchedItem, image, cached) in
                    guard let self = self else { return }
                    if cached && image != nil {
                        cell?.imageView.image = image
                    } else {
                        if let item = fetchedItem as? ImageIdentifier, image != nil {
                            var snapshot = self.dataSource.snapshot()
                            if snapshot.itemIdentifiers.contains(item) {
                                snapshot.reloadItems([item])
                            }
                            self.dataSource.apply(snapshot, animatingDifferences: true)
                        }
                    }
                }
                
                return cell
            }
            
            var snapshot = NSDiffableDataSourceSnapshot<Section, ImageIdentifier>()
            snapshot.appendSections([.main])
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}
