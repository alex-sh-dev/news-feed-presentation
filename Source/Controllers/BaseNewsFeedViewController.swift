//
//  BaseNewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/13/26.
//

import UIKit
import Combine

class BaseNewsFeedViewController<SectionIdentifierType, ItemIdentifierType, NewsViewModelType>: UIViewController, NewsFeedInterface where SectionIdentifierType: Hashable, SectionIdentifierType: Sendable, ItemIdentifierType: Hashable, ItemIdentifierType: Sendable, NewsViewModelType: BaseNewsViewModel {
    typealias NewsFeedViewDiffableDataSource = UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
    typealias NewsFeedDiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>

    let kNewsSegueIdentifier = "NewsSegueIdentifier"

    @IBOutlet weak var newsFeed: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.isHidden = true
        }
    }

    var dataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>!

    var newsViewModel = BaseNewsViewModel.createObject(fromType: NewsViewModelType.self)

    var identifiersActionSub: AnyCancellable!

    deinit {
        easyLog(String(describing: self))
        ImageLoader.shared.cancelAllTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.newsFeed.delegate = self
        self.configureDataSource()
        self.configureLayout()
    }

    func startIdentifierToScrollItem(sender: Any?) -> NewsItemIdentifier? {
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let newsFeedVC = segue.destination.children.first as? NewsFeedViewController else {
            return
        }

        if let identifier = startIdentifierToScrollItem(sender: sender) {
            newsFeedVC.startIdentifier = identifier
        }
    }

    func shouldHandleCellSelection() -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !self.shouldHandleCellSelection() {
            return
        }
        let cell = collectionView.cellForItem(at: indexPath)
        self.performSegue(withIdentifier: kNewsSegueIdentifier, sender: cell)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y > 0 && scrollView.reachedBottom() {
            self.newsViewModel.requestNews()
        }
    }

    func configureDataSource() {}

    func configureLayout() {}
}
