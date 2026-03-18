//
//  PreviewNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

enum PreviewNewsIdentifiersAction {
    case empty
    case fill
    case replaceAll
}

class PreviewNewsViewModel: BaseActingNewsViewModel<PreviewNewsIdentifiersAction> {
    private var requestItemsCount: Int = 0

    required init() {
        super.init()
    }

    override func newsUpdatedSubHandler() -> ([UInt]) -> Void {
        { [weak self] ids in
            guard let self = self else { return }
            if ids.isEmpty {
                if self.identifiers.isEmpty {
                    self.identifiersActionPub.send(.empty)
                }
                return
            }
            let storage = NewsStorage.shared
            let identifiers = Array(storage.news.keys.sorted(by: >)
                .prefix(self.requestItemsCount))
            
            let oldIdentifiers = self.identifiers
            self.identifiers = identifiers
            if oldIdentifiers.isEmpty {
                self.identifiersActionPub.send(.fill)
            } else if identifiers.count != oldIdentifiers.count ||
                        identifiers != oldIdentifiers {
                self.identifiersActionPub.send(.replaceAll)
            }
        }
    }

    @discardableResult
    override func requestItems(page: UInt = 1, count: UInt) -> Bool {
        self.requestItemsCount = Int(count)
        return super.requestItems(page: page, count: count)
    }
}
