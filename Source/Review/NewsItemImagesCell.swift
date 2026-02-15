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
    
    static let identifier = "NewsItemImagesCellIdentifier"
    
    private var imageUrlMap: [ImageIdentifier: URL] = [:]
    
    var imageUrls: [URL] = [] {
        didSet {
            DispatchQueue.main.async {
                self.imageUrlMap.removeAll()
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteAllItems()
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            
            DispatchQueue.main.async {
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
                return self.imageUrls.count > 1
            }
            
            self.dataSource = UICollectionViewDiffableDataSource<Section, ImageIdentifier>(collectionView: self.imageCollection) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: ImageIdentifier) -> UICollectionViewCell? in
                
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImageCell.identifier, for: indexPath) as? NewsItemImageCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImageCell.identifier)'")
                }
                
                guard let imageUrl = self.imageUrlMap[identifier] else {
                    return cell
                }
                
                ImageLoader.shared.load(url: imageUrl, item: identifier, beforeLoad: {
                    self.setDefaultImage(for: cell.imageView)
                }) {
                    (fetchedItem, image, cached) in
                    if cached && image != nil {
                        cell.imageView.image = image
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
    
    private func setDefaultImage(for imageView: UIImageView) {
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray
    }
}
