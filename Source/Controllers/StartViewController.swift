//
//  StartViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit
import Combine

class StartViewController: UIViewController {
    private struct Constants {
        static let kNewsItemCount = 10
        static let kNewsItemReserve = 5
    }
    
    private enum Section {
        case main
    }
    
    private enum NewsItemIdentifier: Hashable {
        case value(UInt)
        case supplementary
        
        var rawValue: UInt {
            get {
                switch self {
                case .supplementary:
                    return UInt.max
                case .value(let val):
                    return val
                }
            }
        }
    }
    
    @IBOutlet weak var previewNewsFeed: UICollectionView! {
        didSet {
            previewNewsFeed.alwaysBounceHorizontal = true
        }
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, NewsItemIdentifier>!
    private var newsUpdatedSubscriber: AnyCancellable!
    
    private func extractIdentifiers() -> [NewsItemIdentifier] {
        let storage = NewsStorage.shared
        var identifiers: [NewsItemIdentifier]!
        storage.lock.with {
            identifiers = Array(storage.news.keys
                .sorted(by: >)
                .prefix(Constants.kNewsItemCount))
                .compactMap{ NewsItemIdentifier.value($0) }
        }
        
        return identifiers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureLayout()
        
        newsUpdatedSubscriber = NewsParser.shared.newsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                if ids.isEmpty {
                    return
                }
                
                guard let self = self else { return }
                
                var identifiers = self.extractIdentifiers()
                if identifiers.isEmpty {
                    return
                }
                
                var snapshot = self.dataSource.snapshot()
                let oldIdentifiers = snapshot.itemIdentifiers
                if oldIdentifiers.isEmpty {
                    if snapshot.numberOfSections == 0 {
                        snapshot.appendSections([.main])
                    }
                    identifiers.append(.supplementary)
                    snapshot.appendItems(identifiers)
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                } else if identifiers.count != oldIdentifiers.count ||
                            identifiers != oldIdentifiers {
                    snapshot.deleteAllItems()
                    snapshot.appendSections([.main])
                    identifiers.append(.supplementary)
                    snapshot.appendItems(identifiers)
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let newsFeedVC = segue.destination.children.first as? NewsFeedViewController else {
            return
        }
        
        guard let previewItem = sender as? PreviewNewsItemCell else {
            return
        }
        
        newsFeedVC.startIdentifier = previewItem.itemIdentifier
    }
    
    private func setDefaultImage(for imageView: UIImageView) {
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, NewsItemIdentifier>(collectionView: self.previewNewsFeed) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemIdentifier) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            if identifier == .supplementary {
                return UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsSupplementaryCell.self)
            }
            
            let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsItemCell.self)
            
            var newsItem: NewsItem?
            NewsStorage.shared.lock.with {
                newsItem = NewsStorage.shared.news[identifier.rawValue]
            }
            
            if newsItem == nil {
                return cell
            }
            
            cell.itemIdentifier = .value(newsItem!.id)
            cell.headerLabel.text = newsItem!.title
            
            guard let url = newsItem!.titleImageUrl else {
                self.setDefaultImage(for: cell.imageView)
                return cell
            }
            
            ImageLoader.shared.load(url: url, item: identifier, beforeLoad: {
                self.setDefaultImage(for: cell.imageView)
            }) { [weak self]
                (fetchedItem, image, cached) in
                guard let self = self else { return }
                if cached && image != nil {
                    cell.imageView.image = image
                } else {
                    if let idfr = fetchedItem as? NewsItemIdentifier, image != nil {
                        var updatedSnapshot = self.dataSource.snapshot()
                        updatedSnapshot.reloadItems([idfr])
                        self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            
            return cell
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItemIdentifier>()
        snapshot.appendSections([.main])
        var identifiers = self.extractIdentifiers()
        if identifiers.isEmpty {
            NewsParser.shared.requestData(
                count: UInt(Constants.kNewsItemCount + Constants.kNewsItemReserve))
        } else {
            identifiers.append(.supplementary)
            snapshot.appendItems(identifiers)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureLayout() {
        self.previewNewsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
