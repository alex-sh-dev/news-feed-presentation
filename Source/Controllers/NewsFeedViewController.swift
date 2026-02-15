//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

public enum NewsItemSection: Hashable {
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

    var startIdentifier: NewsItemSection = .notValid
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    //?? общий класс с StartViewController
    
    private var dataSource: UICollectionViewDiffableDataSource<NewsItemSection, NewsItemPartIdentifier>!
        
    private var newsUpdatedSubscriber: AnyCancellable!
    private var imageUrlsUpdatedSubscriber: AnyCancellable!
    
    private var newsTextRequester = FullNewsTextRequester()
    
    private var fullTextContents: [UInt: String]!
    private var showInFullPressed: Set<UInt> = [] //?? rename?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.fullTextContents.isEmpty {
            return
        }
        //?? to sp func
        NewsStorage.shared.lock.with {
            NewsStorage.shared.fullTextContents
                .merge(self.fullTextContents) { (current, _) in current }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //?? to sp func
        NewsStorage.shared.lock.with {
            self.fullTextContents = NewsStorage.shared.fullTextContents
        }
        
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
                
                self.activityIndicator.stopAnimating() //?? to sp func ? everywhere
                self.activityIndicator.isHidden = true
                
                if ids.isEmpty {
                    return
                }
                
                var snapshot = self.dataSource.snapshot()
                let identifiers = snapshot.sectionIdentifiers.compactMap{ $0.rawValue }
                
                let newIdentifiers = Set(ids).subtracting(Set(identifiers))
                
                if newIdentifiers.isEmpty {
                    return
                }
                
                //?? common code
                
                let storage = NewsStorage.shared
                storage.lock.with {
                    let sections = Array(newIdentifiers)
                        .sorted(by: >)
                        .compactMap{ NewsItemSection.value($0) }
                    snapshot.appendSections(sections)
                    for section in sections {
                        let id = section.rawValue
                        var identifiers: [NewsItemPartIdentifier] = [.main(id)]
                        if storage.news[id]?.titleImageUrl != nil {
                            identifiers.append(.image(id))
                        }
                        snapshot.appendItems(identifiers, toSection: section)
                    }
                }
                
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
    }
    
    private func requestNewItems() {
        let total = UInt(self.newsFeed.numberOfSections)
        let page = (total + Constants.kItemCountPerPage) / Constants.kItemCountPerPage
        NewsParser.shared.requestData(page: page, count: Constants.kItemCountPerPage)
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<NewsItemSection, NewsItemPartIdentifier>(collectionView: self.newsFeed) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemPartIdentifier) -> UICollectionViewCell? in
            
            if indexPath.section == collectionView.numberOfSections - 1 {
                self.requestNewItems()
            }
            
            switch identifier {
            case .main(let id):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemCell.identifier, for: indexPath) as? NewsItemCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemCell.identifier)'")
                }
                
                //?? common code refactor
                
                var newsItem: NewsItem?
                NewsStorage.shared.lock.with {
                    newsItem = NewsStorage.shared.news[id]
                }
                
                if newsItem == nil {
                    return cell
                }
                
                cell.titleLabel.text = newsItem!.title
                cell.dateLabel.text = newsItem!.publishedDate?.relativeDate()
                cell.categoryLabel.text = newsItem!.categoryType
                cell.descriptionLabel.text = newsItem!.description
                
                //?? activity indicator start
                
                if let newsItemId = newsItem?.id { //?? remake? //?? rename?
                    if self.showInFullPressed.contains(newsItemId) {
                        cell.descriptionLabel.text = self.fullTextContents[newsItemId]
                        cell.hideShowInFullButton(true)
                        
                    } else {
                        if cell.showInFullButton.isHidden {
                            cell.hideShowInFullButton(false)
                        }
                        
                        if let url = newsItem?.fullUrl { //?? so ok
                            cell.showInFullTappedHandler = {
                                if let fullText = self.fullTextContents[newsItemId] {
                                    self.showInFullPressed.insert(newsItemId)
                                    cell.descriptionLabel.text = fullText //??
                                    cell.hideShowInFullButton(true)
                                    let ctx = UICollectionViewLayoutInvalidationContext()
                                    ctx.invalidateItems(at: [indexPath])
                                    self.newsFeed.collectionViewLayout.invalidateLayout(with: ctx) //??
                                } else {
                                    self.newsTextRequester.start(for: url, with: newsItem!.id!) {
                                        itemId, dataText in
                                        if let text = dataText, !text.isEmpty,
                                           let id = itemId as? UInt, id == newsItem!.id {
                                            //?? common
                                            self.fullTextContents[id] = text
                                            self.showInFullPressed.insert(id)
                                            cell.descriptionLabel.text = dataText //??
                                            cell.hideShowInFullButton(true)
                                            let ctx = UICollectionViewLayoutInvalidationContext()
                                            ctx.invalidateItems(at: [indexPath])
                                            self.newsFeed.collectionViewLayout.invalidateLayout(with: ctx) //??
                                        }
                                    }
                                }
                            }
                        } else {
                            cell.hideShowInFullButton(true)
                        }
                    }
                }
                
                return cell
            case .image(let id):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImagesCell.identifier, for: indexPath) as? NewsItemImagesCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImagesCell.identifier)'")
                }
                
                //?? common code
                
                var imageUrls: [URL] = []
                NewsStorage.shared.lock.with {
                    guard let newsItem = NewsStorage.shared.news[id],
                          let url = newsItem.titleImageUrl else {
                        fatalError("Error: ") //?? вообще возможна такая ситуация?
                    }
                    
                    imageUrls.append(url)
                    if let additionalUrls = NewsStorage.shared.imageUrls[id] {
                        imageUrls.append(contentsOf: additionalUrls)
                    }
                }
                
                cell.imageUrls = imageUrls //??
                
                //?? how to clear
                
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<NewsItemSection, NewsItemPartIdentifier>()
        
        let storage = NewsStorage.shared
        storage.lock.with {
            let sections = Array(storage.news.keys)
                .sorted(by: >)
                .compactMap{ NewsItemSection.value($0) }
            snapshot.appendSections(sections)
            for section in sections {
                let id = section.rawValue
                var identifiers: [NewsItemPartIdentifier] = [.main(id)]
                if storage.news[id]?.titleImageUrl != nil {
                    identifiers.append(.image(id))
                }
                snapshot.appendItems(identifiers, toSection: section)
            }
        }
        
        self.dataSource.apply(snapshot, animatingDifferences: false)
        
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
