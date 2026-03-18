//
//  NewsFeedGridViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit
import Combine

class NewsFeedGridViewController: NewsFeedListViewController<Section, UInt, NewsViewModel, GridItemCell, NewsFeedDetailsViewController> {
    private struct Constants {
        static let kItemCountPerPage: UInt = 20
    }

    static let kNewsGridSegueIdentifier = "NewsGridSegueIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsViewModel.desiredRequestedItemCount = Constants.kItemCountPerPage
    }

    override func identifiersActionSubcriberDidSet() {
        self.newsViewModel.fillIdentifiersFromStorage()
    }

    override func configureIdentifiersActionSubcriber() -> AnyCancellable? {
        return self.newsViewModel.identifiersActionPub
            .sink { [weak self] action in
                guard let self = self else { return }
                var snapshot = self.dataSource.snapshot()
                var animate = true
                switch action {
                case .reloadImages(let id):
                    if snapshot.itemIdentifiers.contains(id) {
                        snapshot.reconfigureItems([id])
                    }
                case .appendItems(let newIdentifiers, _):
                    self.activityIndicator.setAction(.stop)
                    snapshot.appendItems(newIdentifiers)
                case .fill(let identifiers, _):
                    snapshot = NewsFeedDiffableDataSourceSnapshot()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(identifiers)
                    animate = false
                case .itemsRequested:
                    self.activityIndicator.setAction(.start)
                    return
                }
                self.dataSource.apply(snapshot, animatingDifferences: animate)
            }
    }

    override func startIdentifierToScrollItem(for details: NewsFeedDetailsViewController, sender: Any?) -> NewsItemIdentifier {
        if let previewItem = sender as? GridItemCell {
            return previewItem.itemIdentifier
        }

        return .notValid
    }

    override func newsItemId(for indexPath: IndexPath) -> UInt? {
        return self.dataSource.itemIdentifier(for: indexPath)
    }

    override func cellRegistrationHandler(cell: GridItemCell, indexPath: IndexPath, item: NewsItem) {
        cell.configure(item: item)
        cell.itemIdentifier = .value(item.value.id)
    }

    override func dataSourceCellProvider(collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? {
        let newsItem = self.newsViewModel.newsItem(at: identifier)!
        return collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: newsItem
        )
    }

    override func configureLayout() -> UICollectionViewLayout {
        return GridNewsCompositionalLayout()
    }
}
