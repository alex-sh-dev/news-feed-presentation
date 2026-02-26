//
//  PreviewNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

class PreviewNewsViewModel: BaseNewsViewModel {
    enum IdentifiersAction {
        case empty
        case fill
        case replaceAll
    }
    
    private var requestItemsCount: Int = 0
    final let identifiersActionPub = PassthroughSubject<IdentifiersAction, Never>()
    
    override func newsUpdatedSubHandler() -> ([UInt]) -> Void {
        { [weak self] ids in
            guard let self = self else { return }
            if ids.isEmpty {
                if self.identifiers.isEmpty {
                    self.identifiersActionPub.send(.empty)
                }
                return
            }
            var identifiers: [UInt]!
            let storage = NewsStorage.shared
            storage.lock.with {
                identifiers = Array(storage.news.keys.sorted(by: >)
                    .prefix(self.requestItemsCount))
            }
            
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
    
    override func requestItems(page: UInt = 1, count: UInt) {
        self.requestItemsCount = Int(count)
        super.requestItems(page: page, count: count)
    }
}
