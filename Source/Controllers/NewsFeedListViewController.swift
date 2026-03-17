//
//  NewsFeedListViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/17/26.
//

import UIKit

class NewsFeedListViewController<SectionIdentifierType: Hashable & Sendable, ItemIdentifierType: Hashable & Sendable, NewsViewModelType: BaseNewsViewModel, CollectionViewCellType: ImageCollectionViewCell>: NewsFeedViewController<SectionIdentifierType, ItemIdentifierType, NewsViewModelType, CollectionViewCellType> {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let child = segue.destination.children.first
        guard let newsFeedVC = child as? NewsFeedDetailsViewController else {
            return
        }

        if let identifier = self.startIdentifierToScrollItem(sender: sender) {
            newsFeedVC.startIdentifier = identifier
        }
    }

    func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        return nil
    }
}
