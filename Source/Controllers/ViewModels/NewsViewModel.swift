//
//  NewsViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

enum NewsItemPart {
    case textImage
    case onlyText
}

enum NewsIdentifiersAction {
    case reloadImages(UInt)
    case fill([UInt], [NewsItemPart])
    case appendItems([UInt], [NewsItemPart])
    case itemsRequested
    
    var rawValue: UInt {
        get {
            switch self {
            case .reloadImages(let id):
                return id
            default:
                return UInt.max
            }
        }
    }
}

class NewsViewModel: BaseActingNewsViewModel<NewsIdentifiersAction> {
    private var newsItemUpdatedSub: AnyCancellable!

    required init() {
        super.init()
    }

    private func sendIdentifiers(_ identifiers: [UInt], append: Bool = true) {
        var identifiersToSend: [UInt] = []
        var newsItemParts: [NewsItemPart] = []
        for identifier in identifiers {
            guard let newsItem = newsItem(at: identifier) else {
                continue
            }
            self.identifiers.append(identifier)
            identifiersToSend.append(identifier)
            
            if newsItem.value.titleImageUrl == nil {
                newsItemParts.append(.onlyText)
            } else {
                newsItemParts.append(.textImage)
            }
        }
        
        if identifiersToSend.isEmpty {
            return
        }
        
        let action: NewsIdentifiersAction = append ?
            .appendItems(identifiersToSend, newsItemParts) :
            .fill(identifiersToSend, newsItemParts)
        
        self.identifiersActionPub.send(action)
    }
    
    override func newsUpdatedSubHandler() -> ([UInt]) -> Void {
        { [weak self] ids in
            if ids.isEmpty { return }
            guard let self = self else { return }

            let newIdentifiers = Set(ids).subtracting(Set(self.identifiers)).sorted(by: >)
            if newIdentifiers.isEmpty {
                return
            }

            self.sendIdentifiers(newIdentifiers)
        }
    }
    
    final func fillIdentifiersFromStorage() {
        let identifiers = NewsStorage.shared.news.keys.sorted(by: >)
        self.sendIdentifiers(identifiers, append: false)
    }
    
    override func bindToPublishers() {
        super.bindToPublishers()
        self.newsItemUpdatedSub = NewsParser.shared.newsItemParser.newsItemUpdatedPub
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.identifiersActionPub.send(.reloadImages(id))
            }
    }

    override func requestNews() -> Bool {
        if super.requestNews() {
            self.identifiersActionPub.send(.itemsRequested)
            return true
        }
        return false
    }
}
