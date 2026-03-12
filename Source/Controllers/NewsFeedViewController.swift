//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

class NewsFeedViewController: UIViewController, NewsFeedInterface, NewsItemCellDelegate {
    enum NewsItemPartIdentifier: Hashable {
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
        static let kItemCountPerPage: UInt = 10
    }
    
    @IBOutlet weak var newsFeed: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.isHidden = true
        }
    }

    private var startIdentifierRaw: NewsItemIdentifier = .notValid
    var startIdentifier: NewsItemIdentifier {
        set { startIdentifierRaw = newValue }
        get {
            switch (startIdentifierRaw) {
            case .index(let index):
                if let identifier = self.newsViewModel.id(at: index) {
                    return .value(identifier)
                } else {
                    return .notValid
                }
            default:
                return startIdentifierRaw
            }
        }
    }
    
    var identifiersActionSub: AnyCancellable! {
        didSet {
            self.newsViewModel.fillIdentifiersFromStorage()
        }
    }
    var newsViewModel: NewsFeedViewModel = NewsFeedViewModel()

    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    var dataSource: UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>!
    
    deinit {
        easyLog(String(describing: self))
        ImageLoader.shared.cancelAllTasks()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always

        self.newsFeed.delegate = self
        self.configureDataSource()
        self.configureLayout()
        
        self.identifiersActionSub = self.newsViewModel.identifiersActionPub
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .reloadImages(let id):
                    self.reloadItems([.image(id)], animate: true)
                case .appendItems(let newIdentifiers, let newsParts):
                    self.activityIndicator.setAction(.stop)
                    var snapshot = self.dataSource.snapshot()
                    self.updateSnapshot(&snapshot, with: newIdentifiers, and:newsParts, animate: true)
                case .fill(let identifiers, let newsParts):
                    var snapshot = NSDiffableDataSourceSnapshot<NewsItemIdentifier, NewsItemPartIdentifier>()
                    self.updateSnapshot(&snapshot, with: identifiers, and: newsParts, animate: false)
                    self.scrollToStartItem()
                }
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

    private func scrollToStartItem() {
        let identifier = self.startIdentifier
        if identifier != .notValid,
            let sectionIndex = self.dataSource.snapshot().indexOfSection(identifier) {
            let indexPath = IndexPath(row: 0, section: sectionIndex)
            let id = identifier.rawValue
            if self.newsViewModel.newsItemText(for: id) != nil {
                self.reloadItems([.main(id)], animate: true)
            }

            DispatchQueue.main.async {
                self.newsFeed.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }
    }

    private func reloadItems(_ identifiers: [NewsItemPartIdentifier], animate: Bool = false) {
        var snapshot = self.dataSource.snapshot()
        for idfr in identifiers {
            if snapshot.itemIdentifiers.contains(idfr) {
                snapshot.reconfigureItems([idfr])
            }
        }
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func requestNewsParty() {
        let total = UInt(self.newsFeed.numberOfSections)
        let itemCount = Constants.kItemCountPerPage
        let page = (total + itemCount) / itemCount
        self.newsViewModel.requestItems(page: page, count: itemCount)
        self.activityIndicator.setAction(.start)
    }

    private func requestNewsPartyIfNeeded(using indexPath: IndexPath) {
        let current = indexPath.section
        let total = UInt(self.newsFeed.numberOfSections)
        if current == total - Constants.kItemCountPerPage / 2 {
            self.requestNewsParty()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let imagesCell = cell as? NewsItemImagesCell else {
            return
        }

        ImageLoader.shared.suspendTasks(for: imagesCell.visibleImageUrls)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY >= contentHeight - frameHeight {
            self.requestNewsParty()
        }
    }

    func showInFullTapped(cell: NewsItemCell) {
        let id = cell.newsItemId
        guard let text = self.newsViewModel.newsItemText(for: id) else {
            return
        }

        cell.descriptionLabel.text = text
        cell.hideShowInFullButton(true)

        guard let indexPath = self.newsFeed.indexPath(for: cell) else {
            return
        }

        let ctx = UICollectionViewLayoutInvalidationContext()
        ctx.invalidateItems(at: [indexPath])
        self.newsFeed.collectionViewLayout.invalidateLayout(with: ctx)
    }

    func shareTapped(cell: NewsItemCell) {
        guard let newsItem = self.newsViewModel.newsItem(at: cell.newsItemId),
              let fullUrl = newsItem.fullUrl else {
            return
        }
        let activityVC = UIActivityViewController.linkOpener(url: fullUrl, sourceView: cell.shareButton)
        self.present(activityVC, animated: true)
    }

    func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<NewsItemIdentifier, NewsItemPartIdentifier>(collectionView: self.newsFeed) { [unowned self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemPartIdentifier) -> UICollectionViewCell? in
            let model = self.newsViewModel
            switch identifier {
            case .main(let id):
                let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemCell.self)
                cell.delegate = self
                self.requestNewsPartyIfNeeded(using: indexPath)
                cell.configure(with: id, from: model)
                return cell
            case .image(let id):
                let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemImagesCell.self)
                cell.imageUrls = model.imageUrls(for: id)
                return cell
            }
        }
    }

    func configureLayout() {
        self.newsFeed.collectionViewLayout = NewsCompositionalLayout()
    }
}
