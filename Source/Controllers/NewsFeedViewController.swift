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
    let kNewsDetailsSegueIdentifier = "NewsDetailsSegueIdentifier"

    private(set) var imagesPrefetcher: NewsImagesPrefetcher!
    private var visibleCellsWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        self.imagesPrefetcher = self.configurePrefetchDataSource()
        self.newsFeed.prefetchDataSource = self.imagesPrefetcher
        super.viewDidLoad()
    }

    func shouldHandleCellSelection() -> Bool {
        return false
    }

    func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let child = segue.destination.children.first
        guard let newsFeedVC = child as? NewsFeedDetailsViewController else {
            return
        }

        if let identifier = self.startIdentifierToScrollItem(sender: sender) {
            newsFeedVC.startIdentifier = identifier
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !self.shouldHandleCellSelection() {
            return
        }
        let cell = collectionView.cellForItem(at: indexPath)
        self.performSegue(withIdentifier: kNewsDetailsSegueIdentifier, sender: cell)
    }

    func newsItemId(for indexPath: IndexPath) -> UInt? { return nil }

    func configurePrefetchDataSource() -> NewsImagesPrefetcher? {
        return NewsImagesPrefetcher(model: self.newsViewModel) {
            [weak self] indexPath in
            return self?.newsItemId(for: indexPath)
        }
    }

    // TODO: need refactor, workaround to revive 'frozen' cells (using configuration) to load images after canceling
    private func updateImagesForVisibleCells() {
        self.visibleCellsWorkItem?.cancel()
        self.visibleCellsWorkItem = DispatchWorkItem {
            [weak self] in
            guard let self = self else { return }
            if self.visibleCellsWorkItem?.isCancelled ?? true {
                return
            }
            let cells = self.newsFeed.visibleCells
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

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.updateImagesForVisibleCells()
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.imagesPrefetcher.collectionView(collectionView, cancelPrefetchingForItemsAt: [indexPath])
    }
}
