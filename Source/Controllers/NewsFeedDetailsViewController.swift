//
//  NewsFeedDetailsViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

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

class NewsFeedDetailsViewController: NewsFeedViewController<NewsItemIdentifier, NewsItemPartIdentifier, NewsViewModel, ImageCollectionViewCellDefault>, NewsFeedDetailsInterface, NewsItemCellDelegate {
    private struct Constants {
        static let kItemCountPerPage: UInt = 10
    }

    class NewsFeedImagesPrefetcher : NewsImagesPrefetcher {
        override func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
            indexPaths.forEach { indexPath in
                if let cell = collectionView.cellForItem(at: indexPath) as? NewsItemImagesCell {
                    ImageLoader.shared.cancelTasks(for: cell.visibleImageUrls)
                }
            }
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

    @IBAction func onClose(_ sender: Any) {
        self.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsViewModel.desiredRequestedItemCount = Constants.kItemCountPerPage
    }

    override func configurePrefetchDataSource() -> NewsImagesPrefetcher? {
        return NewsFeedImagesPrefetcher(model: self.newsViewModel) {
            [weak self] indexPath in
            return self?.newsItemId(for: indexPath)
        }
    }

    override func identifiersActionSubcriberDidSet() {
        self.newsViewModel.fillIdentifiersFromStorage()
    }

    override func configureIdentifiersActionSubcriber() -> AnyCancellable? {
        return self.newsViewModel.identifiersActionPub
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
                    var snapshot = NewsFeedDiffableDataSourceSnapshot()
                    self.updateSnapshot(&snapshot, with: identifiers, and: newsParts, animate: false)
                    self.scrollToStartItem()
                case .itemsRequested:
                    self.activityIndicator.setAction(.start)
                }
            }
    }

    private func updateSnapshot(_ snapshot: inout NewsFeedDiffableDataSourceSnapshot, with identifiers: [UInt], and parts:[NewsItemPart], animate: Bool = false) {
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
                snapshot.reconfigureItems([idfr])
            }
        }
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }

    func scrollToStartItem() {
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

    override func newsItemId(for indexPath: IndexPath) -> UInt? {
        let identifier = self.dataSource.itemIdentifier(for: indexPath)
        switch identifier {
        case .image(let id):
            return id
        default:
            return nil
        }
    }

    override func newsItemRow(for indexPath: IndexPath) -> Int {
        return indexPath.section
    }

    func onShowInFull(for cell: NewsItemCell) {
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

    func onShare(for cell: NewsItemCell) {
        guard let newsItem = self.newsViewModel.newsItem(at: cell.newsItemId),
              let fullUrl = newsItem.fullUrl else {
            return
        }
        let activityVC = UIActivityViewController.linkOpener(url: fullUrl, sourceView: cell.shareButton)
        self.present(activityVC, animated: true)
    }

    override func updateImagesForVisibleCells(collectionView: UICollectionView, cell: UICollectionViewCell?) {
        if let imagesCell = cell as? NewsItemImagesCell {
            super.updateImagesForVisibleCells(collectionView: imagesCell.imageCollection, cell: nil)
        }
    }

    override func dataSourceCellProvider(collectionView: UICollectionView, indexPath: IndexPath, identifier: NewsItemPartIdentifier) -> UICollectionViewCell? {
        let model = self.newsViewModel
        switch identifier {
        case .main(let id):
            let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemCell.self)
            cell.delegate = self
            cell.configure(with: id, from: model)
            return cell
        case .image(let id):
            let cell = UICollectionViewCell.dequeueReusableCell(from: collectionView, for: indexPath, cast: NewsItemImagesCell.self)
            cell.imageUrls = model.imageUrls(for: id)
            return cell
        }
    }

    override func configureLayout() -> UICollectionViewLayout {
        return NewsCompositionalLayout()
    }
}
