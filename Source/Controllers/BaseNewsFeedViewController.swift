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

    final var dataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>!
    final var newsViewModel = BaseNewsViewModel.createObject(fromType: NewsViewModelType.self)
    final var identifiersActionSub: AnyCancellable? {
        didSet {
            self.identifiersActionSubcriberDidSet()
        }
    }

    private(set) var cellRegistration: CollectionViewCellRegistration!
    private(set) var imagesPrefetcher: NewsImagesPrefetcher!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagesPrefetcher = self.configurePrefetchDataSource()
        self.newsFeed.prefetchDataSource = self.imagesPrefetcher
        self.newsFeed.delegate = self
        self.configureDataSource()
        self.newsFeed.collectionViewLayout = self.configureLayout()
        self.identifiersActionSub = self.configureIdentifiersActionSubcriber()
    }

    deinit {
        easyLog(String(describing: self))
    }

    func configurePrefetchDataSource() -> NewsImagesPrefetcher? {
        return NewsImagesPrefetcher(model: self.newsViewModel) {
            [weak self] indexPath in
            return self?.newsItemId(for: indexPath)
        }
    }

    func identifiersActionSubcriberDidSet() {}

    func configureIdentifiersActionSubcriber() -> AnyCancellable? { return nil }

    func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        return nil
    }

    func newsItemId(for indexPath: IndexPath) -> UInt? { return nil }

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

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.imagesPrefetcher.collectionView(collectionView, cancelPrefetchingForItemsAt: [indexPath])
    }

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
