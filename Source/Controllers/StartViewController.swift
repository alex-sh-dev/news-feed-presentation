//
//  StartViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit
import Combine

class StartViewController: UIViewController, UICollectionViewDelegate {
    private struct Constants {
        static let kNewsItemCount: UInt = 10
        static let kNewsItemReserve: UInt = 5
        static let kNewsSegueIdfr = "NewsSegueIdentifier"
        static let kNewsGridSegueIdfr = "NewsGridSegueIdentifier"
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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBAction func newsButtonTapped(_ sender: Any) {
        if self.newsViewModel.isEmpty() {
            return
        }
        let idfr = UIDevice.isPad ? Constants.kNewsGridSegueIdfr : Constants.kNewsSegueIdfr
        self.performSegue(withIdentifier: idfr, sender: sender)
    }

    private var noNewsLabel: UILabel?

    private var dataSource: UICollectionViewDiffableDataSource<Section, NewsItemIdentifier>!
    private var identifiersActionSub: AnyCancellable! {
        didSet {
            let itemsCount = UInt(Constants.kNewsItemCount + Constants.kNewsItemReserve)
            self.newsViewModel.requestItems(count: itemsCount)
            self.activityIndicator.setAction(.start)
        }
    }
    private var newsViewModel = PreviewNewsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previewNewsFeed.delegate = self
        self.configureDataSource()
        self.configureLayout()
        
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
            self.noNewsLabel = CenteredLabel(text: "No news", parent: self.previewNewsFeed)
        }
    }

    private func hideNoNewsIfNeeded() {
        if self.noNewsLabel != nil {
            self.noNewsLabel!.removeFromSuperview()
            self.noNewsLabel = nil
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let newsFeedVC = segue.destination.children.first as? NewsFeedViewController else {
            return
        }

        if let previewItem = sender as? PreviewNewsItemCell {
            newsFeedVC.startIdentifier = previewItem.itemIdentifier
        } else if sender is PreviewNewsSupplementaryCellButton {
            newsFeedVC.startIdentifier = .index(Constants.kNewsItemCount)
        }
    }
    
    private func transformedIdentifiers() -> [NewsItemIdentifier] {
        return self.newsViewModel.identifiers
            .prefix(Int(Constants.kNewsItemCount))
            .compactMap{ NewsItemIdentifier.value($0) }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.performSegue(withIdentifier: Constants.kNewsSegueIdfr, sender: cell)
    }

    private func configureDataSource() {
        let newsItemCellRegistration = UICollectionView.CellRegistration<PreviewNewsItemCell, NewsItem> {
            cell, _, item in
            cell.configure(with: item.title, and: item.titleImageUrl)
            cell.itemIdentifier = .value(item.id)
        }

        self.dataSource = UICollectionViewDiffableDataSource<Section, NewsItemIdentifier>(collectionView: self.previewNewsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemIdentifier) -> UICollectionViewCell? in
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

        let snapshot = NSDiffableDataSourceSnapshot<Section, NewsItemIdentifier>()
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func configureLayout() {
        self.previewNewsFeed.collectionViewLayout = PreviewNewsCompositionalLayout()
    }
}
