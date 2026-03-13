//
//  NewsFeedGridViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit
import Combine

class NewsFeedGridViewController: BaseNewsFeedViewController<Section, UInt, NewsFeedViewModel> {
    private struct Constants {
        static let kItemCountPerPage: UInt = 20
    }

    override var identifiersActionSub: AnyCancellable! {
        didSet {
            self.newsViewModel.fillIdentifiersFromStorage()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.identifiersActionSub = self.newsViewModel.identifiersActionPub
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
        self.newsViewModel.desiredRequestedItemCount = Constants.kItemCountPerPage
    }

    override func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        if let previewItem = sender as? GridItemCell {
            return previewItem.itemIdentifier
        }

        return nil
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let id = self.dataSource.itemIdentifier(for: indexPath),
              let newsItem = self.newsViewModel.newsItem(at: id),
              let url = newsItem.titleImageUrl else {
            return
        }

        ImageLoader.shared.suspendTasks(for: [url])
    }

    override func shouldHandleCellSelection() -> Bool {
        return true
    }

    override func configureDataSource() {
        let gridCellRegistration = UICollectionView.CellRegistration<GridItemCell, NewsItem> {
            cell, _, item in
            cell.configure(item: item)
            cell.itemIdentifier = .value(item.id)
        }

        self.dataSource = NewsFeedViewDiffableDataSource(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? in
            self.newsViewModel.requestNewsIfNeeded(currentItemRow: UInt(indexPath.row))
            let newsItem = self.newsViewModel.newsItem(at: identifier)!
            return collectionView.dequeueConfiguredReusableCell(
                using: gridCellRegistration,
                for: indexPath,
                item: newsItem
            )
        }
    }

    override func configureLayout() {
        self.newsFeed.collectionViewLayout = GridNewsCompositionalLayout()
    }
}
