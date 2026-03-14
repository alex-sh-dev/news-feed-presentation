//
//  NewsFeedInterface.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit
import Combine

protocol NewsFeedInterface: UICollectionViewDelegate {
    associatedtype NewsViewModelType: BaseNewsViewModel
    var newsViewModel: NewsViewModelType { get set }

    var newsFeed: UICollectionView! { get set }
    var activityIndicator: UIActivityIndicatorView! { get set }

    associatedtype SectionIdentifierType: Hashable
    associatedtype ItemIdentifierType: Hashable
    var dataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>! { get set }
    var identifiersActionSub: AnyCancellable? { get set }

    func dataSourceCellProvider(collectionView: UICollectionView,
                                indexPath: IndexPath,
                                identifier: ItemIdentifierType) -> UICollectionViewCell?

    func configureLayout() -> UICollectionViewLayout
}
