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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.isHidden = true
        }
    }

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
                
                self.activityIndicator.stopAnimating() //?? to sp func ? everywhere
                self.activityIndicator.isHidden = true
                
                if ids.isEmpty {
                    return
                }
                
                var snapshot = self.dataSource.snapshot()
                let identifiers = snapshot.sectionIdentifiers
                
                let newIdentifiers = Set(ids).subtracting(Set(identifiers))
                
                if newIdentifiers.isEmpty {
                    return
                }

                //?? common code
                
                let storage = NewsStorage.shared
                var sections: [UInt: [String]]! = [:]
                storage.lock.with {
                    for newIdfr in newIdentifiers { //??
                        guard let newsItem = storage.news[newIdfr] else {
                            continue
                        }
                        
                        var idfrs: [String] = []
                        idfrs.append(String(newIdfr) + "*")
                        if newsItem.titleImageUrl != nil {
                            idfrs.append(String(newIdfr) + "+")
                        }
                        sections[newIdfr] = idfrs
                    }
                }
                
                if sections.isEmpty {
                    return
                }
                
                snapshot.appendSections(Array(sections.keys.sorted(by: >)))
                for section in sections {
                    snapshot.appendItems(section.value, toSection: section.key)
                }

                self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<UInt, String>(collectionView: self.newsFeed) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: String) -> UICollectionViewCell? in
            
            if indexPath.section == collectionView.numberOfSections - 1 && identifier.contains("*") { //??
                let total = collectionView.numberOfSections
                let page = UInt((total + 5) / 5) //?? to conts
                NewsParser.shared.requestData(page: page, count: 5)
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            
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
                cell.dateLabel.text = newsItem!.publishedDate?.relativeDate()
                cell.categoryLabel.text = newsItem!.categoryType
                cell.descriptionLabel.text = newsItem!.description
                
                return cell
            } else if identifier.contains("+") {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsItemImagesCell.identifier, for: indexPath) as? NewsItemImagesCell else {
                    fatalError("Error: couldn't create cell with identifier: '\(NewsItemImagesCell.identifier)'")
                }
                
                //?? common code
                
                var imageUrls: [URL] = []
                let index = UInt(identifier.dropLast(1))!
                NewsStorage.shared.lock.with {
                    guard let newsItem = NewsStorage.shared.news[index],
                          let url = newsItem.titleImageUrl else {
                        fatalError("error") //??
                    }
                    
                    imageUrls.append(url)
                    if let additionalUrls = NewsStorage.shared.imageUrls[index] {
                        imageUrls.append(contentsOf: additionalUrls)
                    }
                }
                
                cell.imageUrls = imageUrls //??
                
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
        
        let theSections = Array(sections.keys.sorted(by: >)) //?? all?
  
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
