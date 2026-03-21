//
//  BaseNewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/13/26.
//

import UIKit
import Combine

typealias CollectionViewCellDefault = UICollectionViewCell

class BaseNewsFeedViewController<SectionIdentifierType: Hashable & Sendable, ItemIdentifierType: Hashable & Sendable, NewsViewModelType: BaseNewsViewModel, CollectionViewCellType: UICollectionViewCell>: UIViewController, NewsFeedInterface, UICollectionViewDelegate {
    typealias NewsFeedViewDiffableDataSource = UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    typealias NewsFeedDiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
    typealias CollectionViewCellRegistration = UICollectionView.CellRegistration<CollectionViewCellType, NewsItem>

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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsFeed.delegate = self
        self.configureDataSource()
        self.newsFeed.collectionViewLayout = self.configureLayout()
        self.identifiersActionSub = self.configureIdentifiersActionSubcriber()
    }

    deinit {
        easyLog(String(describing: self))
    }

    func identifiersActionSubcriberDidSet() {}

    func configureIdentifiersActionSubcriber() -> AnyCancellable? { return nil }

    func cellConfiguredHandler(_ cell: UICollectionViewCell, collectionView: UICollectionView, indexPath: IndexPath) {}

    func cellRegistrationHandler(cell: CollectionViewCellType, indexPath: IndexPath, item: NewsItem) {}

    func dataSourceCellProvider(collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemIdentifierType) -> UICollectionViewCell? {
        return nil
    }

    private func configureDataSource() {
        self.cellRegistration = CollectionViewCellRegistration() {
            [unowned self] cell, indexPath, item in
            self.cellRegistrationHandler(cell: cell, indexPath: indexPath, item: item)
        }
        self.dataSource = NewsFeedViewDiffableDataSource(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ItemIdentifierType) -> UICollectionViewCell? in
            guard let cell = self.dataSourceCellProvider(collectionView: collectionView, indexPath: indexPath, identifier: identifier) else {
                return nil
            }
            self.cellConfiguredHandler(cell, collectionView: collectionView, indexPath: indexPath)
            return cell
        }
    }

    func configureLayout() -> UICollectionViewLayout {
        return UICollectionViewFlowLayout()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {}

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
}
