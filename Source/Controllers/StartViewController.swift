//
//  StartViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit
import Combine

enum PreviewNewsItemIdentifier: Hashable {
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

class StartViewController: NewsFeedListViewController<Section, PreviewNewsItemIdentifier, PreviewNewsViewModel, PreviewNewsItemCell, NewsFeedDetailsViewController> {
    private struct Constants {
        static let kNewsItemCount: UInt = 10
        static let kNewsItemReserve: UInt = 5
    }

    @IBAction func onNews(_ sender: Any) {
        if self.newsViewModel.isEmpty() {
            return
        }
        var identifier = NewsFeedDetailsViewController.segueIdentifier
        if UIDevice.isPad {
            identifier = NewsFeedGridViewController.kNewsGridSegueIdentifier
        }
        self.performSegue(withIdentifier: identifier, sender: sender)
    }

    private var noNewsLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsFeed.alwaysBounceHorizontal = true
        self.isPageLoadingEnabled = false
    }

    override func identifiersActionSubcriberDidSet() {
        let itemsCount = UInt(Constants.kNewsItemCount + Constants.kNewsItemReserve)
        self.newsViewModel.requestItems(count: itemsCount)
        self.activityIndicator.setAction(.start)
    }

    override func configureIdentifiersActionSubcriber() -> AnyCancellable? {
        return self.newsViewModel.identifiersActionPub
            .sink { [weak self] action in
                guard let self = self else { return }
                var identifiers = self.transformedIdentifiers()
                var snapshot: NewsFeedDiffableDataSourceSnapshot!
                var animate: Bool = false
                switch action {
                case .fill:
                    snapshot = NewsFeedDiffableDataSourceSnapshot()
                    self.activityIndicator.setAction(.stop)
                case .replaceAll:
                    animate = true
                    snapshot = self.dataSource.snapshot()
                    snapshot.deleteAllItems()
                case .empty:
                    self.activityIndicator.setAction(.stop)
                    self.showNoNews()
                    return
                }
                if snapshot.numberOfSections == 0 {
                    snapshot.appendSections([.main])
                }
                identifiers.append(.supplementary)
                snapshot.appendItems(identifiers)
                self.dataSource.apply(snapshot, animatingDifferences: animate)
                self.hideNoNewsIfNeeded()
            }
    }

    private func transformedIdentifiers() -> [PreviewNewsItemIdentifier] {
        return self.newsViewModel.identifiers
            .prefix(Int(Constants.kNewsItemCount))
            .compactMap{ PreviewNewsItemIdentifier.value($0) }
    }

    private func showNoNews() {
        if self.noNewsLabel == nil {
            self.noNewsLabel = CenteredLabel(text: "No news", parent: self.newsFeed)
        }
    }

    private func hideNoNewsIfNeeded() {
        if self.noNewsLabel != nil {
            self.noNewsLabel!.removeFromSuperview()
            self.noNewsLabel = nil
        }
    }

    override func startIdentifierToScrollItem(for details: NewsFeedDetailsViewController, sender: Any?) -> NewsItemIdentifier {
        if let previewItem = sender as? PreviewNewsItemCell {
            return previewItem.itemIdentifier
        } else if sender is PreviewNewsSupplementaryCellButton {
            return .index(Constants.kNewsItemCount)
        }
        return .notValid
    }

    override func newsItemId(for indexPath: IndexPath) -> UInt? {
        return self.dataSource.itemIdentifier(for: indexPath)?.rawValue
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        scrollView.contentOffset.y = 0
    }

    override func cellRegistrationHandler(cell: PreviewNewsItemCell, indexPath: IndexPath, item: NewsItem) {
        cell.configure(with: item.value.title, and: item.value.titleImageUrl)
        cell.itemIdentifier = .value(item.id)
    }

    override func dataSourceCellProvider(collectionView: UICollectionView, indexPath: IndexPath, identifier: PreviewNewsItemIdentifier) -> UICollectionViewCell? {
        if identifier == .supplementary {
            return UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsSupplementaryCell.self)
        }

        let newsItem = self.newsViewModel.newsItem(at: identifier.rawValue)!
        return collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: newsItem
        )
    }

    override func configureLayout() -> UICollectionViewLayout {
        return PreviewNewsCompositionalLayout()
    }
}
