//
//  NewsItemImagesCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/12/26.
//

import UIKit

private enum Section { //?? дубликат?
    case main
}

class NewsItemImagesCell: UICollectionViewCell {
    
    static let identifier = "NewsItemImagesCellIdentifier"
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, String>!
    
    @IBOutlet weak var imageCollection: UICollectionView! {
        didSet {
            
            self.imageCollection.collectionViewLayout = ImagesCompositionalLayout {
                let count = self.imageUrls?.count ?? 0 //?? может быть nil
                return count > 1
            }
            
            self.dataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: self.imageCollection) {
                (collectionView: UICollectionView, indexPath: IndexPath, identifier: String) -> UICollectionViewCell? in
                
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImageCell.identifier, for: indexPath) as? NewsItemImageCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImageCell.identifier)'")
                }
                
                guard let imageUrl = self.imageUrlMap?[identifier] else {
                    return cell
                }
                
                ImageLoader.shared.load(url: imageUrl, item: identifier, beforeLoad: {
                    self.setDefaultImage(for: cell.imageView)
                }) {
                    (fetchedItem, image, cached) in
                    if cached && image != nil {
                        cell.imageView.image = image
                    } else {
                        if let item = fetchedItem as? String, image != nil {
                            var updatedSnapshot = self.dataSource.snapshot()
                            if updatedSnapshot.itemIdentifiers.contains(item) {
                                updatedSnapshot.reloadItems([item])
                            }
                            self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                        }
                    }
                }
                
                return cell
            }
            
            var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
            snapshot.appendSections([.main])
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
    
    private var imageUrlMap: [String: URL]? //?? rename
    
    var imageUrls: [URL]? { //?? rename
        didSet {
            //?? if nil
            
            DispatchQueue.main.async {
                self.imageUrlMap = nil //??
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteAllItems()
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            
            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.appendSections([.main])
                
                //?? so ok?
                
                self.imageUrlMap = [:] //??
                var identifiers: [String] = []
                for url in self.imageUrls! {
                    let uuid = UUID().uuidString
                    self.imageUrlMap![uuid] = url
                    identifiers.append(uuid)
                }
                snapshot.appendItems(identifiers)
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func setDefaultImage(for imageView: UIImageView) { //?? дубликат
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray
    }
}
