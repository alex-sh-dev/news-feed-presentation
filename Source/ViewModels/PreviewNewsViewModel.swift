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
        case fill
        case replaceAll
    }
    
    private var requestItemsCount: Int = 0
    final let identifiersActionPublisher = PassthroughSubject<IdentifiersAction, Never>()
    
    override func newsUpdatedSubscriberHandler() -> ([UInt]) -> Void {
        { [weak self] ids in
            if ids.isEmpty {
                return
            }
            guard let self = self else { return }
            
            var identifiers: [UInt]!
            let storage = NewsStorage.shared
            storage.lock.with {
                identifiers = Array(storage.news.keys.sorted(by: >)
                    .prefix(self.requestItemsCount))
            }
            
            let oldIdentifiers = self.identifiers
            self.identifiers = identifiers
            if oldIdentifiers.isEmpty {
                self.identifiersActionPublisher.send(.fill)
            } else if identifiers.count != oldIdentifiers.count ||
                        identifiers != oldIdentifiers {
                self.identifiersActionPublisher.send(.replaceAll)
            }
        }
    }
    
    override func requestItems(page: UInt = 1, count: UInt) {
        self.requestItemsCount = Int(count)
        super.requestItems(page: page, count: count)
    }
}
