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
    
    private var newsItemUpdatedSubscriber: AnyCancellable!
    
    private var newsTextRequester = FullNewsTextRequester()
    
    final var fullTextContents: [UInt: String] = [:]
    final var showInFullPressed: Set<UInt> = []
    
    final let identifiersActionPublisher = PassthroughSubject<IdentifiersAction, Never>()
    
    override init() {
        super.init()
        self.restoreFullTextContents()
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
        
        self.identifiersActionPublisher.send(action)
    }
    
    override func newsUpdatedSubscriberHandler() -> ([UInt]) -> Void {
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
        newsItemUpdatedSubscriber = NewsParser.shared.newsItemParser.newsItemUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.identifiersActionPublisher.send(.reloadImages(id))
                let storage = NewsStorage.shared
                storage.lock.with {
                    self?.fullTextContents[id] = storage.fullTextContents[id]
                }
            }
    }
    
    private func restoreFullTextContents() {
        let storage = NewsStorage.shared
        storage.lock.with {
            self.fullTextContents = storage.fullTextContents
        }
    }
    
    final func requestText(forNewsItemWith id: UInt,
                             completionHandler: @escaping (String, UInt) -> Void) {
        if let fullText = self.fullTextContents[id] {
            self.showInFullPressed.insert(id)
            completionHandler(fullText, id)
            return
        }
        
        guard let newsItem = self.newsItem(at: id),
              let url = newsItem.fullUrl else {
            return
        }
        
        self.newsTextRequester.start(for: url, with: id) { [weak self]
            fetchedId, dataText in
            guard let self = self else { return }
            
            guard let text = dataText, !text.isEmpty,
                  let id = fetchedId as? UInt  else {
                return
            }
            
            self.fullTextContents[id] = dataText
            self.showInFullPressed.insert(id)
            
            completionHandler(text, id)
        }
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
