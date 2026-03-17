//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/16/26.
//

import UIKit

typealias ImageCollectionViewCellDefault = ImageCollectionViewCell

class NewsFeedViewController<SectionIdentifierType: Hashable & Sendable, ItemIdentifierType: Hashable & Sendable, NewsViewModelType: BaseNewsViewModel, CollectionViewCellType: ImageCollectionViewCell>: BaseNewsFeedViewController<SectionIdentifierType, ItemIdentifierType, NewsViewModelType, CollectionViewCellType> {
    let kOperationDelaySec: TimeInterval = 0.5

    private(set) var imagesPrefetcher: NewsImagesPrefetcher!
    private var visibleCellsWorkItem: DispatchWorkItem?

    var isPageLoadingEnabled = true

    override func viewDidLoad() {
        self.imagesPrefetcher = self.configurePrefetchDataSource()
        self.newsFeed.prefetchDataSource = self.imagesPrefetcher
        super.viewDidLoad()
    }

    func newsItemId(for indexPath: IndexPath) -> UInt? { return nil }

    func newsItemRow(for indexPath: IndexPath) -> Int {
        return indexPath.row
    }

    func configurePrefetchDataSource() -> NewsImagesPrefetcher? {
        return NewsImagesPrefetcher(model: self.newsViewModel) {
            [weak self] indexPath in
            return self?.newsItemId(for: indexPath)
        }
    }

    func presentViewController(forSelected cell: UICollectionViewCell) -> SegueIdentifier? {
        return nil
    }

    // TODO: need refactor, workaround to revive 'frozen' cells (using configuration) to load images after canceling
    func updateImagesForVisibleCells(collectionView: UICollectionView, cell: UICollectionViewCell?) {
        self.visibleCellsWorkItem?.cancel()
        self.visibleCellsWorkItem = DispatchWorkItem {
            [weak self, weak collectionView] in
            guard let self = self else { return }
            if self.visibleCellsWorkItem?.isCancelled ?? true {
                return
            }
            let cells = collectionView?.visibleCells ?? []
            cells.forEach { cell in
                if let imageCell = cell as? CollectionViewCellType {
                    var state = imageCell.imageConfigurationState
                    state.setUpdateImageIfNeeded = true
                    imageCell.updateConfiguration(using: state)
                }
            }
        }
        let time: DispatchTime = .now() + kOperationDelaySec
        DispatchQueue.main.asyncAfter(deadline: time, execute: self.visibleCellsWorkItem!)
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        if self.isPageLoadingEnabled,
           scrollView.contentOffset.y > 0,
           scrollView.reachedBottom() {
            self.newsViewModel.requestNews()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath),
           let segueIdfr = self.presentViewController(forSelected: cell) {
            self.performSegue(withIdentifier: segueIdfr, sender: cell)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.updateImagesForVisibleCells(collectionView: collectionView, cell: cell)
        if self.isPageLoadingEnabled {
            self.newsViewModel.requestNewsIfNeeded(currentItemRow: UInt(self.newsItemRow(for: indexPath)))
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.imagesPrefetcher.collectionView(collectionView, cancelPrefetchingForItemsAt: [indexPath])
    }
}
