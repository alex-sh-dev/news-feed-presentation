//
//  NewsFeedGridViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit
import Combine

class NewsFeedGridViewController: UIViewController, NewsFeedInterface {
    private struct Constants {
        static let kItemCountPerPage: UInt = 20
    }

    @IBOutlet weak var newsFeed: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.isHidden = true
        }
    }

    var identifiersActionSub: AnyCancellable! {
        didSet {
            self.newsViewModel.fillIdentifiersFromStorage()
        }
    }
    var newsViewModel: NewsFeedViewModel = NewsFeedViewModel()
    var dataSource: UICollectionViewDiffableDataSource<Section, UInt>!

    deinit {
        easyLog(String(describing: self))
        ImageLoader.shared.cancelAllTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.newsFeed.delegate = self
        self.configureDataSource()
        self.configureLayout()

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
                    snapshot = NSDiffableDataSourceSnapshot<Section, UInt>()
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

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let id = self.dataSource.itemIdentifier(for: indexPath),
              let newsItem = self.newsViewModel.newsItem(at: id),
              let url = newsItem.titleImageUrl else {
            return
        }

        ImageLoader.shared.suspendTasks(for: [url])
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.reachedBottom() {
            self.newsViewModel.requestNews(desiredItemCount: Constants.kItemCountPerPage)
        }
    }

    func configureDataSource() {
        let gridCellRegistration = UICollectionView.CellRegistration<GridItemCell, NewsItem> {
            cell, _, item in
            cell.configure(item: item)
            cell.itemIdentifier = .value(item.id)
        }

        self.dataSource = UICollectionViewDiffableDataSource<Section, UInt>(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? in
            self.newsViewModel.requestNewsIfNeeded(currentItemRow: UInt(indexPath.row),
                                                   desiredItemCount: Constants.kItemCountPerPage)
            let newsItem = self.newsViewModel.newsItem(at: identifier)!
            return collectionView.dequeueConfiguredReusableCell(
                using: gridCellRegistration,
                for: indexPath,
                item: newsItem
            )
        }
    }

    func configureLayout() {
        self.newsFeed.collectionViewLayout = GridNewsCompositionalLayout()
    }
}
