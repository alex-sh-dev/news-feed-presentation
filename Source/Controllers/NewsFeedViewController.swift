//
//  NewsFeedViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/9/26.
//

import UIKit
import Combine

class NewsFeedViewController: UIViewController {
    @IBOutlet weak var newsFeed: UICollectionView!
    
    var startIdentifier: UInt = 0
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    //?? общий класс с StartViewController
    
    private var dataSource: UICollectionViewDiffableDataSource<UInt, String>! //?? String -> hash?
        
    private var newsUpdatedSubscriber: AnyCancellable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        configureDataSource()
        configureLayout()
        
        newsUpdatedSubscriber = NewsParser.shared.newsUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink {
            ids in
//            if ids.isEmpty {
//                return
//            }
//
//            let identifiers = self.extractIdentifiers()
//            if identifiers.isEmpty {
//                return
//            }
//
//            var snapshot = self.dataSource.snapshot()
//            let oldIdentifiers = snapshot.itemIdentifiers
//            if oldIdentifiers.isEmpty {
//                if snapshot.numberOfSections == 0 {
//                    snapshot.appendSections([.main])
//                }
//                snapshot.appendItems(identifiers)
//                self.dataSource.apply(snapshot, animatingDifferences: false)
//            } else if identifiers.count != oldIdentifiers.count ||
//                        identifiers != oldIdentifiers {
//                snapshot.deleteAllItems()
//                snapshot.appendSections([.main])
//                snapshot.appendItems(identifiers)
//                self.dataSource.apply(snapshot, animatingDifferences: false)
//            }
        }
    }
    
//    private func extractIdentifiers() -> [UInt] { //??
//        let storage = NewsStorage.shared
//        var identifiers: [UInt]!
//        storage.lock.with {
//            identifiers = Array(storage.news.keys.sorted(by: >)
//                .prefix(15)) //??
//        }
//
//        return identifiers
//    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<UInt, String>(collectionView: self.newsFeed) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: String) -> UICollectionViewCell? in
            
            if identifier.contains("*") {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemCell.identifier, for: indexPath) as? NewsItemCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemCell.identifier)'")
                }
                
                //?? common code refactor
                
                var newsItem: NewsItem?
                NewsStorage.shared.lock.with {
                    let index = UInt(identifier.dropLast(1))!
                    newsItem = NewsStorage.shared.news[index]
                }
                
                if newsItem == nil {
                    return cell
                }
                
                cell.titleLabel.text = newsItem!.title
                cell.dateLabel.text = newsItem!.publishedDate?.formatted(date: .long, time: .omitted) //?? today and etc?
                cell.categoryLabel.text = newsItem!.categoryType //??
                cell.descriptionLabel.text = newsItem!.description! //??
                
                return cell
            } else if identifier.contains("+") {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImagesCell.identifier, for: indexPath) as? NewsItemImagesCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImagesCell.identifier)'")
                }
                
                //?? common code
                
                var newsItem: NewsItem?
                NewsStorage.shared.lock.with {
                    let index = UInt(identifier.dropLast(1))!
                    newsItem = NewsStorage.shared.news[index]
                }
                
                if newsItem == nil {
                    return cell
                }
                
                guard let url = newsItem!.titleImageUrl else {
                    fatalError("error") //??
                }
                
                cell.imageUrls = [url] //??
                
                //?? how to clear
                
                return cell
            }
            
            return nil //?? so ok? fatalError
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<UInt, String>()
        
        let storage = NewsStorage.shared
        var sections: [UInt: [String]]! = [:]
        storage.lock.with {
            for newsItem in storage.news {
                var idfrs: [String] = []
                idfrs.append(String(newsItem.key) + "*")
                if newsItem.value.titleImageUrl != nil {
                    idfrs.append(String(newsItem.key) + "+")
                }
                sections[newsItem.key] = idfrs
            }
        }
        
        let theSections = Array(sections.keys.sorted(by: >)
            .prefix(15)) //??
  
        snapshot.appendSections(theSections)
        for section in sections {
            snapshot.appendItems(section.value, toSection: section.key)
        }
        
        self.dataSource.apply(snapshot, animatingDifferences: false)
        
        DispatchQueue.main.async {
            let dssnapshot = self.dataSource.snapshot()
            if self.startIdentifier > 0,
                let sectionIndex = dssnapshot.indexOfSection(self.startIdentifier) {
                self.newsFeed.scrollToItem(at: IndexPath(row: 0, section: sectionIndex),
                                           at: .top, animated: false)
            }
        }
    }
    
    private func configureLayout() {
        self.newsFeed.collectionViewLayout = NewsCompositionalLayout()
    }
}
