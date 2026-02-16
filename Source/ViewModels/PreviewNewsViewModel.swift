//
//  PreviewNewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

enum IdentifiersAction {
    case load
    case replaceAll
}

class PreviewNewsViewModel: BaseNewsViewModel {
    public let identifiersActionPublisher = PassthroughSubject<IdentifiersAction, Never>()
    
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
                self.identifiersActionPublisher.send(.load)
            } else if identifiers.count != oldIdentifiers.count ||
                        identifiers != oldIdentifiers {
                self.identifiersActionPublisher.send(.replaceAll)
            }
        }
    }
}
