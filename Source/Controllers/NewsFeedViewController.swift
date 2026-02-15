//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

public enum NewsItemIdentifier: Hashable {
    case notValid
    case value(UInt)
    
    var rawValue: UInt {
        get {
            switch self {
            case .notValid:
                return 0
            case .value(let val):
                return val
            }
        }
    }
}

class NewsFeedViewController: UIViewController {
    private enum NewsItemPartIdentifier: Hashable {
        case main(UInt)
        case image(UInt)
        
        var rawValue: UInt {
            get {
                switch self {
                case .main(let val):
                    return val
                case .image(let val):
                    return val
                }
            }
        }
    }
    
    private struct Constants {
        static let kItemCountPerPage: UInt = 5
    }
    
    @IBOutlet weak var newsFeed: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.isHidden = true
        }
    }

    var startIdentifier: NewsItemIdentifier = .notValid
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>!
        
    private var newsUpdatedSubscriber: AnyCancellable!
    private var imageUrlsUpdatedSubscriber: AnyCancellable!
    
    private var newsTextRequester = FullNewsTextRequester()
    
    private var fullTextContents: [UInt: String]!
    private var showInFullPressed: Set<UInt> = []
    
    private func saveFullTextContents() {
        if self.fullTextContents.isEmpty {
            return
        }

        let storage = NewsStorage.shared
        storage.lock.with {
            storage.fullTextContents
                .merge(self.fullTextContents) { (current, _) in current }
        }
    }
    
    private func restoreFullTextContents() {
        let storage = NewsStorage.shared
        storage.lock.with {
            self.fullTextContents = storage.fullTextContents
        }
    }
    
    private func stopActivityIndicatorAnimating() {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    private func startActivityIndicatorAnimating() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveFullTextContents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreFullTextContents()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        configureDataSource()
        configureLayout()
        
        imageUrlsUpdatedSubscriber = NewsImageUrlsExtractor.shared.imageUrlsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                id in
                
                var snapshot = self.dataSource.snapshot()
                let idfr = NewsItemPartIdentifier.image(id)
                if snapshot.itemIdentifiers.contains(idfr) {
                    snapshot.reloadItems([idfr])
                }
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        
        newsUpdatedSubscriber = NewsParser.shared.newsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                ids in
                
                self.stopActivityIndicatorAnimating()
                
                if ids.isEmpty {
                    return
                }
                
                var snapshot = self.dataSource.snapshot()
                let identifiers = snapshot.sectionIdentifiers.compactMap{ $0.rawValue }
                
                let newIdentifiers = Set(ids).subtracting(Set(identifiers))
                
                if newIdentifiers.isEmpty {
                    return
                }
                
                self.updateSnapshot(&snapshot, with: Array(newIdentifiers), animate: true)
            }
    }
    
    private func updateSnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<NewsItemIdentifier, NewsItemPartIdentifier>, with identifiers: [UInt], animate: Bool = false) {
        let sections = identifiers
            .sorted(by: >)
            .compactMap{ NewsItemIdentifier.value($0) }
        snapshot.appendSections(sections)
        
        let storage = NewsStorage.shared
        storage.lock.with {
            for section in sections {
                let id = section.rawValue
                var identifiers: [NewsItemPartIdentifier] = [.main(id)]
                if storage.news[id]?.titleImageUrl != nil {
                    identifiers.append(.image(id))
                }
                snapshot.appendItems(identifiers, toSection: section)
            }
        }
        
        self.dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    private func requestNewsParty() {
        let total = UInt(self.newsFeed.numberOfSections)
        let page = (total + Constants.kItemCountPerPage) / Constants.kItemCountPerPage
        NewsParser.shared.requestData(page: page, count: Constants.kItemCountPerPage)
        startActivityIndicatorAnimating()
    }
    
    private func newsItem(at id: UInt) -> NewsItem? {
        var newsItem: NewsItem?
        NewsStorage.shared.lock.with {
            newsItem = NewsStorage.shared.news[id]
        }
    
        return newsItem
    }
    
    private func fillDescription(for cell: NewsItemCell, with text: String, at indexPath: IndexPath) {
        cell.descriptionLabel.text = text
        cell.hideShowInFullButton(true)
        let ctx = UICollectionViewLayoutInvalidationContext()
        ctx.invalidateItems(at: [indexPath])
        self.newsFeed.collectionViewLayout.invalidateLayout(with: ctx)
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>(collectionView: self.newsFeed) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemPartIdentifier) -> UICollectionViewCell? in
            
            if indexPath.section == collectionView.numberOfSections - 1 {
                self.requestNewsParty()
            }
            
            switch identifier {
            case .main(let id):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemCell.identifier, for: indexPath) as? NewsItemCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemCell.identifier)'")
                }
                
                guard let newsItem = self.newsItem(at: id) else {
                    return cell
                }
                
                cell.titleLabel.text = newsItem.title
                cell.dateLabel.text = newsItem.publishedDate?.relativeDate()
                cell.categoryLabel.text = newsItem.categoryType
                cell.descriptionLabel.text = newsItem.description
                
                if self.showInFullPressed.contains(id) {
                    cell.descriptionLabel.text = self.fullTextContents[id]
                    cell.hideShowInFullButton(true)
                } else {
                    if cell.showInFullButton.isHidden {
                        cell.hideShowInFullButton(false)
                    }
                    
                    guard let fullUrl = newsItem.fullUrl else {
                        cell.hideShowInFullButton(true)
                        return cell
                    }
                    
                    cell.showInFullTappedHandler = {
                        if let fullText = self.fullTextContents[id] {
                            self.showInFullPressed.insert(id)
                            self.fillDescription(for: cell, with: fullText, at: indexPath)
                        } else {
                            // TODO: add animating for Show in full button
                            self.newsTextRequester.start(for: fullUrl, with: id) {
                                fetchedId, dataText in
                                if let text = dataText, !text.isEmpty,
                                   let itemId = fetchedId as? UInt, id == itemId {
                                    self.fullTextContents[id] = text
                                    self.showInFullPressed.insert(itemId)
                                    self.fillDescription(for: cell, with: text, at: indexPath)
                                }
                            }
                        }
                    }
                }
                
                return cell
            case .image(let id):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImagesCell.identifier, for: indexPath) as? NewsItemImagesCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImagesCell.identifier)'")
                }
                
                guard let newsItem = self.newsItem(at: id) else {
                    return cell
                }
                
                var imageUrls: [URL] = []
                let storage = NewsStorage.shared
                storage.lock.with {
                    if let url = newsItem.titleImageUrl {
                        imageUrls.append(url)
                    }

                    if let additionalUrls = storage.imageUrls[id] {
                        imageUrls.append(contentsOf: additionalUrls)
                    }
                }
                
                cell.imageUrls = imageUrls
                
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<NewsItemIdentifier, NewsItemPartIdentifier>()
        let storage = NewsStorage.shared
        var identifiers: [UInt]!
        storage.lock.with {
            identifiers = Array(storage.news.keys)
        }
        
        updateSnapshot(&snapshot, with: identifiers, animate: false)
        DispatchQueue.main.async {
            if self.startIdentifier != .notValid,
                let sectionIndex = self.dataSource.snapshot().indexOfSection(self.startIdentifier) {
                self.newsFeed.scrollToItem(at: IndexPath(row: 0, section: sectionIndex),
                                           at: .top, animated: false)
            }
        }
    }
    
    private func configureLayout() {
        self.newsFeed.collectionViewLayout = NewsCompositionalLayout()
    }
}
