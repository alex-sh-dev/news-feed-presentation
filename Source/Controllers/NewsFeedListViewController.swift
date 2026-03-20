//
//  NewsFeedListViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/17/26.
//

import UIKit

class NewsFeedListViewController<SectionIdentifierType: Hashable & Sendable, ItemIdentifierType: Hashable & Sendable, NewsViewModelType: BaseNewsViewModel, CollectionViewCellType: ImageCollectionViewCell, NewsFeedDetailsType: NewsFeedDetailsInterface>: NewsFeedViewController<SectionIdentifierType, ItemIdentifierType, NewsViewModelType, CollectionViewCellType>, NewsFeedListInterface {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let child = segue.destination.children.first
        guard var details = child as? NewsFeedDetailsType else {
            return
        }

        let identifier = self.startIdentifierToScrollItem(for: details, sender: sender)
        details.startIdentifier = identifier
    }

    func startIdentifierToScrollItem(for details: NewsFeedDetailsType, sender: Any?) -> NewsFeedDetailsType.NewsItemIdentifierType {
        return .notValid
    }

    override func presentViewController(for selectedCell: UICollectionViewCell) -> SegueIdentifier? {
        return NewsFeedDetailsType.segueIdentifier
    }
}
