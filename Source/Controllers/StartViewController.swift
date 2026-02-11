//
//  ViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit
import Combine

private enum Section {
    case main
}

class StartViewController: UIViewController {
    @IBOutlet weak var previewNewsFeed: UICollectionView! {
        didSet {
            previewNewsFeed.alwaysBounceHorizontal = true
        }
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, UInt>!
    private var idsSub: AnyCancellable? //?? how to cancel sub
    
    private struct Constants {
        static let kNewsItemCount = 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureLayout()
        
        idsSub = NewsParser.shared.idsPub.sink { ids in
            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                let identifiers = Array(ids.sorted(by: >).prefix(Constants.kNewsItemCount))
                let oldIdentifiers = snapshot.itemIdentifiers
                if oldIdentifiers.isEmpty {
                    snapshot.appendItems(identifiers)
                } else if identifiers.count != oldIdentifiers.count {
                    snapshot.deleteAllItems()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(identifiers)
                }
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func setDefaultImage(for imageView: UIImageView) {
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, UInt>(collectionView: self.previewNewsFeed) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? in
            
            if indexPath.row == Constants.kNewsItemCount - 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewNewsSupplementaryCell.identifier, for: indexPath) as? PreviewNewsSupplementaryCell
                
                return cell
            }
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewNewsItemCell.identifier, for: indexPath) as? PreviewNewsItemCell else {
                fatalError("Error: couldn't create cell with identifier: '\(PreviewNewsItemCell.identifier)'")
            }
            
            var newsItem: NewsItem?
            NewsStorage.shared.lock.with {
                newsItem = NewsStorage.shared.news[identifier]
            }
            
            if newsItem == nil {
                return cell
            }
            
            cell.headerLabel.text = newsItem!.title
            
            guard let url = newsItem!.titleImageUrl else {
                self.setDefaultImage(for: cell.imageView)
                return cell
            }
            
            ImageLoader.shared.load(url: url, item: newsItem!, beforeLoad: {
                self.setDefaultImage(for: cell.imageView)
            }) {
                (fetchedItem, image, cached) in
                if cached && image != nil {
                    cell.imageView.image = image
                } else {
                    if let item = fetchedItem as? NewsItem, image != nil {
                        var updatedSnapshot = self.dataSource.snapshot()
                        updatedSnapshot.reloadItems([item.id])
                        self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, UInt>()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureLayout() {
        self.previewNewsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
