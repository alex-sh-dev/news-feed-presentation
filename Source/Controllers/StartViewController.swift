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
    private var identifiersActionSubscriber: AnyCancellable! {
        didSet {
            let itemsCount = UInt(Constants.kNewsItemCount + Constants.kNewsItemReserve)
            self.newsViewModel.requestItems(count: itemsCount)
        }
    }
    private var newsViewModel = PreviewNewsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureLayout()
        
        identifiersActionSubscriber = self.newsViewModel.identifiersActionPublisher
            .sink { [weak self] action in
                guard let self = self else { return }
                var identifiers = self.transformedIdentifiers()
                var snapshot = self.dataSource.snapshot()
                var animate: Bool = true
                switch action {
                case .fill:
                    animate = false
                case .replaceAll:
                    snapshot.deleteAllItems()
                }
                if snapshot.numberOfSections == 0 {
                    snapshot.appendSections([.main])
                }
                identifiers.append(.supplementary)
                snapshot.appendItems(identifiers)
                self.dataSource.apply(snapshot, animatingDifferences: animate)
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
    
    private func transformedIdentifiers() -> [NewsItemIdentifier] {
        return self.newsViewModel.identifiers
            .prefix(Constants.kNewsItemCount)
            .compactMap{ NewsItemIdentifier.value($0) }
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, NewsItemIdentifier>(collectionView: self.previewNewsFeed) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemIdentifier) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            if identifier == .supplementary {
                return UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsSupplementaryCell.self)
            }
            
            let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsItemCell.self)
            
            guard let newsItem = self.newsViewModel.newsItem(at: identifier.rawValue) else {
                return cell
            }
            
            cell.itemIdentifier = .value(newsItem.id)
            cell.headerLabel.text = newsItem.title
            
            guard let url = newsItem.titleImageUrl else {
                cell.setDefaultImage()
                return cell
            }
            
            ImageLoader.shared.load(url: url, item: identifier, beforeLoad: {
                [weak cell] in
                cell?.setDefaultImage()
            }) { [weak self, weak cell]
                (fetchedItem, image, cached) in
                guard let self = self else { return }
                if cached && image != nil {
                    cell?.imageView.image = image
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

        let snapshot = NSDiffableDataSourceSnapshot<Section, NewsItemIdentifier>()
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureLayout() {
        self.previewNewsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
