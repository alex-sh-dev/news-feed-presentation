//
//  NewsFeedViewModel.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/16/26.
//

import Foundation
import Combine

class NewsFeedViewModel: BaseNewsViewModel {
    enum NewsItemPart {
        case textImage
        case onlyText
    }
    
    enum IdentifiersAction {
        case reloadImages(UInt)
        case fill([UInt], [NewsItemPart])
        case appendItems([UInt], [NewsItemPart])
        
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
    
    private var newsItemUpdatedSub: AnyCancellable!
    
    final var showInFullPressed: Set<UInt> = []
    
    final let identifiersActionPub = PassthroughSubject<IdentifiersAction, Never>()
    
    private func sendIdentifiers(_ identifiers: [UInt], append: Bool = true) {
        var identifiersToSend: [UInt] = []
        var newsItemParts: [NewsItemPart] = []
        for identifier in identifiers {
            guard let newsItem = newsItem(at: identifier) else {
                continue
            }
            self.identifiers.append(identifier)
            identifiersToSend.append(identifier)
            
            if newsItem.titleImageUrl == nil {
                newsItemParts.append(.onlyText)
            } else {
                newsItemParts.append(.textImage)
            }
        }
        
        if identifiersToSend.isEmpty {
            return
        }
        
        let action: IdentifiersAction = append ?
            .appendItems(identifiersToSend, newsItemParts) :
            .fill(identifiersToSend, newsItemParts)
        
        self.identifiersActionPub.send(action)
    }
    
    override func newsUpdatedSubHandler() -> ([UInt]) -> Void {
        { [weak self] ids in
            if ids.isEmpty {
                return
            }
            guard let self = self else { return }
            
            let newIdentifiers = Set(ids).subtracting(Set(self.identifiers)).sorted(by: >)
            
            if newIdentifiers.isEmpty {
                return
            }
            
            self.sendIdentifiers(newIdentifiers)
        }
    }
    
    final func fillIdentifiersFromStorage() {
        let storage = NewsStorage.shared
        var identifiers: [UInt]!
        storage.lock.with {
            identifiers = Array(storage.news.keys).sorted(by: >)
        }
        sendIdentifiers(identifiers, append: false)
    }
    
    override func bindToPublishers() {
        super.bindToPublishers()
        newsItemUpdatedSub = NewsParser.shared.newsItemParser.newsItemUpdatedPub
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.identifiersActionPub.send(.reloadImages(id))
            }
    }

    final func newsItemText(for id: UInt) -> String? {
        let storage = NewsStorage.shared
        var text: String?
        storage.lock.with {
            text = storage.newsTexts[id]
        }
        
        if text != nil {
            self.showInFullPressed.insert(id)
        }

        return text
    }
    
    final func imageUrls(for id: UInt) -> [URL] {
        guard let newsItem = self.newsItem(at: id) else {
            return []
        }
        
        var imageUrls: [URL] = []
        if let url = newsItem.titleImageUrl {
            imageUrls.append(url)
        }
        
        let storage = NewsStorage.shared
        storage.lock.with {
            if let additionalUrls = storage.imageUrls[id] {
                imageUrls.append(contentsOf: additionalUrls)
            }
        }
        
        return imageUrls
    }
}
