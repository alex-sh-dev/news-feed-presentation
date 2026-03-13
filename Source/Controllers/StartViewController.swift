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

class StartViewController: BaseNewsFeedViewController<Section, PreviewNewsItemIdentifier, PreviewNewsViewModel> {
    private struct Constants {
        static let kNewsItemCount: UInt = 10
        static let kNewsItemReserve: UInt = 5
        static let kNewsGridSegueIdentifier = "NewsGridSegueIdentifier"
    }

    @IBAction func newsButtonTapped(_ sender: Any) {
        if self.newsViewModel.isEmpty() {
            return
        }
        let idfr = UIDevice.isPad ? Constants.kNewsGridSegueIdentifier : self.kNewsSegueIdentifier
        self.performSegue(withIdentifier: idfr, sender: sender)
    }

    private var noNewsLabel: UILabel?

    override var identifiersActionSub: AnyCancellable! {
        didSet {
            let itemsCount = UInt(Constants.kNewsItemCount + Constants.kNewsItemReserve)
            self.newsViewModel.requestItems(count: itemsCount)
            self.activityIndicator.setAction(.start)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsFeed.alwaysBounceHorizontal = true
        self.identifiersActionSub = self.newsViewModel.identifiersActionPub
            .sink { [weak self] action in
                guard let self = self else { return }
                var identifiers = self.transformedIdentifiers()
                var snapshot = self.dataSource.snapshot()
                var animate: Bool = false
                switch action {
                case .fill:
                    self.activityIndicator.setAction(.stop)
                case .replaceAll:
                    animate = true
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

    override func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        if let previewItem = sender as? PreviewNewsItemCell {
            return previewItem.itemIdentifier
        } else if sender is PreviewNewsSupplementaryCellButton {
           return .index(Constants.kNewsItemCount)
        }
        return nil
    }

    override func shouldHandleCellSelection() -> Bool {
        return true
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset.y = 0
    }

    private func transformedIdentifiers() -> [PreviewNewsItemIdentifier] {
        return self.newsViewModel.identifiers
            .prefix(Int(Constants.kNewsItemCount))
            .compactMap{ PreviewNewsItemIdentifier.value($0) }
    }

    override func configureDataSource() {
        let newsItemCellRegistration = UICollectionView.CellRegistration<PreviewNewsItemCell, NewsItem> {
            cell, _, item in
            cell.configure(with: item.title, and: item.titleImageUrl)
            cell.itemIdentifier = .value(item.id)
        }

        self.dataSource = NewsFeedViewDiffableDataSource(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: PreviewNewsItemIdentifier) -> UICollectionViewCell? in
            if identifier == .supplementary {
                return UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: PreviewNewsSupplementaryCell.self)
            }

            let newsItem = self.newsViewModel.newsItem(at: identifier.rawValue)!
            return collectionView.dequeueConfiguredReusableCell(
                using: newsItemCellRegistration,
                for: indexPath,
                item: newsItem
            )
        }

        dataSource.apply(NewsFeedDiffableDataSourceSnapshot(), animatingDifferences: false)
    }
    
    override func configureLayout() {
        self.newsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
