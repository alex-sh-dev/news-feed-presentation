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
    private var newsUpdatedSubscriber: AnyCancellable!
    
    private struct Constants {
        static let kNewsItemCount = 10
    }
    
    private func extractIdentifiers() -> [UInt] {
        let storage = NewsStorage.shared
        var identifiers: [UInt]!
        storage.lock.with {
            identifiers = Array(storage.news.keys.sorted(by: >)
                .prefix(Constants.kNewsItemCount))
        }
        
        return identifiers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureLayout()
        
        newsUpdatedSubscriber = NewsParser.shared.newsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink {
            updated in
            if !updated {
                return
            }
            
            let identifiers = self.extractIdentifiers()
            if identifiers.isEmpty {
                return
            }
            
            var snapshot = self.dataSource.snapshot()
            let oldIdentifiers = snapshot.itemIdentifiers
            if oldIdentifiers.isEmpty {
                if snapshot.numberOfSections == 0 {
                    snapshot.appendSections([.main])
                }
                snapshot.appendItems(identifiers)
                self.dataSource.apply(snapshot, animatingDifferences: false)
            } else if identifiers.count != oldIdentifiers.count ||
                        identifiers != oldIdentifiers {
                snapshot.deleteAllItems()
                snapshot.appendSections([.main])
                snapshot.appendItems(identifiers)
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
            
            if indexPath.row == collectionView.numberOfItems(inSection: 0) - 1 {
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
        let identifiers = self.extractIdentifiers()
        if identifiers.isEmpty {
            NewsParser.shared.requestData(count: UInt(Constants.kNewsItemCount))
        } else {
            snapshot.appendItems(identifiers)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureLayout() {
        self.previewNewsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
