//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

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
    
    private enum ActivityIndicatorAction {
        case start
        case stop
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
    
    private var identifiersActionSub: AnyCancellable! {
        didSet {
            self.newsViewModel.fillIdentifiersFromStorage()
        }
    }
    private let newsViewModel: NewsFeedViewModel = NewsFeedViewModel()
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>!
    
    deinit {
        easyLog(String(describing: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        configureDataSource()
        configureLayout()
        
        identifiersActionSub = self.newsViewModel.identifiersActionPub
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .reloadImages(let id):
                    self.reloadItems([.image(id)], animate: true)
                case .appendItems(let newIdentifiers, let newsParts):
                    self.actActivityIndicator(.stop)
                    var snapshot = self.dataSource.snapshot()
                    self.updateSnapshot(&snapshot, with: newIdentifiers, and:newsParts, animate: true)
                case .fill(let identifiers, let newsParts):
                    var snapshot = NSDiffableDataSourceSnapshot<NewsItemIdentifier, NewsItemPartIdentifier>()
                    self.updateSnapshot(&snapshot, with: identifiers, and: newsParts, animate: false)
                }
            }
    }
    
    private func actActivityIndicator(_ action: ActivityIndicatorAction) {
        let start = action == .start
        self.activityIndicator.isHidden = !start
        if start {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func updateSnapshot(_ snapshot: inout NSDiffableDataSourceSnapshot<NewsItemIdentifier, NewsItemPartIdentifier>, with identifiers: [UInt], and parts:[NewsFeedViewModel.NewsItemPart], animate: Bool = false) {
        
        let sections = identifiers
            .compactMap{ NewsItemIdentifier.value($0) }
        snapshot.appendSections(sections)
        
        for i in 0..<identifiers.count {
            let id = identifiers[i]
            let part = parts[i]
            var partIdfrs: [NewsItemPartIdentifier] = [.main(id)]
            if part == .textImage {
                partIdfrs.append(.image(id))
            }
            snapshot.appendItems(partIdfrs, toSection: .value(id))
        }
        
        self.dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    private func reloadItems(_ identifiers: [NewsItemPartIdentifier], animate: Bool = false) {
        var snapshot = self.dataSource.snapshot()
        for idfr in identifiers {
            if snapshot.itemIdentifiers.contains(idfr) {
                snapshot.reloadItems([idfr])
            }
        }
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func requestNewsParty() {
        let total = UInt(self.newsFeed.numberOfSections)
        let page = (total + Constants.kItemCountPerPage) / Constants.kItemCountPerPage
        self.newsViewModel.requestItems(page: page, count: Constants.kItemCountPerPage)
        self.actActivityIndicator(.start)
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemPartIdentifier) -> UICollectionViewCell? in
            let model = self.newsViewModel
            switch identifier {
            case .main(let id):
                let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemCell.self)

                if indexPath.section == collectionView.numberOfSections - 1 {
                    self.requestNewsParty()
                }

                guard let newsItem = model.newsItem(at: id) else {
                    return cell
                }
                
                cell.titleLabel.text = newsItem.title
                cell.dateLabel.text = newsItem.publishedDate?.relativeDate()
                cell.categoryLabel.text = newsItem.categoryType
                cell.descriptionLabel.text = newsItem.description
                
                if model.showInFullPressed.contains(id) {
                    cell.descriptionLabel.text = model.newsTexts[id]
                    cell.hideShowInFullButton(true)
                } else {
                    if cell.showInFullButton.isHidden {
                        cell.hideShowInFullButton(false)
                    }
                    
                    if newsItem.fullUrl == nil {
                        cell.hideShowInFullButton(true)
                        return cell
                    }
                    
                    let fillDescription: (String) -> Void = {
                        [weak self, weak cell] text in
                        cell?.descriptionLabel.text = text
                        cell?.hideShowInFullButton(true)
                        let ctx = UICollectionViewLayoutInvalidationContext()
                        ctx.invalidateItems(at: [indexPath])
                        self?.newsFeed.collectionViewLayout.invalidateLayout(with: ctx)
                    }

                    cell.showInFullTappedHandler = { [weak self] in
                        // TODO: add animating for Show in full button
                        self?.newsViewModel.requestText(forNewsItemWith: id) {
                            text, itemId in
                            if id == itemId {
                                fillDescription(text)
                            }
                        }
                    }
                }
                
                return cell
            case .image(let id):
                let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemImagesCell.self)
                cell.imageUrls = model.imageUrls(for: id)
                return cell
            }
        }
        
        DispatchQueue.main.async { [unowned self] in
            switch (self.startIdentifier) {
            case .index(let index):
                if let identifier = self.newsViewModel.id(at: index) {
                    self.startIdentifier = .value(identifier)
                } else {
                    self.startIdentifier = .notValid
                }
            default:
                break
            }

            if self.startIdentifier != .notValid,
                let sectionIndex = self.dataSource.snapshot().indexOfSection(self.startIdentifier) {
                let indexPath = IndexPath(row: 0, section: sectionIndex)
                self.newsViewModel.requestText(forNewsItemWith: self.startIdentifier.rawValue) {
                    [weak self] _, id in
                    self?.reloadItems([.main(id)], animate: true)
                    self?.newsFeed.scrollToItem(at: indexPath, at: .top, animated: true)
                }
                
                self.newsFeed.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }
    }
    
    private func configureLayout() {
        self.newsFeed.collectionViewLayout = NewsCompositionalLayout()
    }
}
