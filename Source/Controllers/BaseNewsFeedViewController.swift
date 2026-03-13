//
//  BaseNewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/13/26.
//

import UIKit
import Combine

typealias CollectionViewCellDefault = UICollectionViewCell

class BaseNewsFeedViewController<SectionIdentifierType, ItemIdentifierType, NewsViewModelType, CollectionViewCellType>: UIViewController, NewsFeedInterface where SectionIdentifierType: Hashable, SectionIdentifierType: Sendable, ItemIdentifierType: Hashable, ItemIdentifierType: Sendable, NewsViewModelType: BaseNewsViewModel, CollectionViewCellType: UICollectionViewCell {
    typealias NewsFeedViewDiffableDataSource = UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    typealias NewsFeedDiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
    typealias CollectionViewCellRegistration = UICollectionView.CellRegistration<CollectionViewCellType, NewsItem>

    let kNewsSegueIdentifier = "NewsSegueIdentifier"

    @IBOutlet weak var newsFeed: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.isHidden = true
        }
    }

    var dataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>!
    var newsViewModel = BaseNewsViewModel.createObject(fromType: NewsViewModelType.self)
    var identifiersActionSub: AnyCancellable!
    private(set) var cellRegistration: CollectionViewCellRegistration!

    deinit {
        easyLog(String(describing: self))
        ImageLoader.shared.cancelAllTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsFeed.delegate = self
        self.configureDataSource()
        self.newsFeed.collectionViewLayout = self.configureLayout()
    }

    func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let newsFeedVC = segue.destination.children.first as? NewsFeedViewController else {
            return
        }

        if let identifier = startIdentifierToScrollItem(sender: sender) {
            newsFeedVC.startIdentifier = identifier
        }
    }

    func shouldHandleCellSelection() -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !self.shouldHandleCellSelection() {
            return
        }
        let cell = collectionView.cellForItem(at: indexPath)
        self.performSegue(withIdentifier: kNewsSegueIdentifier, sender: cell)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y > 0 && scrollView.reachedBottom() {
            self.newsViewModel.requestNews()
        }
    }

    private func configureDataSource() {
        self.cellRegistration = CollectionViewCellRegistration() {
            [unowned self] cell, indexPath, item in
            self.cellRegistrationHandler(cell: cell, indexPath: indexPath, item: item)
        }
        self.dataSource = NewsFeedViewDiffableDataSource(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemIdentifierType) -> UICollectionViewCell? in
            return self.dataSourceCellProvider(collectionView: collectionView, indexPath: indexPath, identifier: identifier)
        }
    }

    func cellRegistrationHandler(cell: CollectionViewCellType, indexPath: IndexPath, item: NewsItem) {}

    func dataSourceCellProvider(collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemIdentifierType) -> UICollectionViewCell? {
        return nil
    }

    func configureLayout() -> UICollectionViewLayout {
        return UICollectionViewFlowLayout()
    }
}
