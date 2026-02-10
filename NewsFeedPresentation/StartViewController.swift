//
//  ViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit
import Combine

class PreliminaryNewsCell: UICollectionViewCell { //?? to sp file
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    static let kIdentifier = String(describing: PreliminaryNewsCell.self)
    
    override var isHighlighted: Bool {
        didSet { //??
            if isHighlighted {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    self.transform = self.transform.scaledBy(x: 0.9, y: 0.9)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                }, completion: nil)
            }
        }
    }
}

class NewsButtonCell: UICollectionViewCell {}

private enum Section {
    case main
}

class StartViewController: UIViewController {
    @IBOutlet weak var newsFeedCollectionView: UICollectionView! //?? rename? +preliminary
    private var dataSource: UICollectionViewDiffableDataSource<Section, UInt>!
    private var idsSub: AnyCancellable? //?? how to cancel sub
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: "urlcache") //??
        
        URLCache.shared = urlCache
        
        urlCache.removeAllCachedResponses()//??
        
//        newsFeedCollectionView.register(PreliminaryNewsCell.self, forCellWithReuseIdentifier: PreliminaryNewsCell.kIdentifier)
        
        self.newsFeedCollectionView.alwaysBounceHorizontal = true
        
        configureDataSource()
        configureLayout()
        
        let endpoint = URL(string: "https://webapi.autodoc.ru/api/news")
        NewsParser.setup(NewsParser.Config(baseEndpoint: endpoint!))//??
        
        idsSub = NewsParser.shared.idsPub.sink { ids in
            //?? sort identifier if needed max = last
            DispatchQueue.main.async {//??
                var snapshot = self.dataSource.snapshot()
                snapshot.appendItems(ids) //?? reload?
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
        
        //?? attempts
        NewsParser.shared.sendRequest(page: 1, count: 10) //?? 10 for start?
    }
    
    private func setDefaultImage(for imageView: UIImageView) {
//        imageView.contentMode = .center
//        let conf = UIImage.SymbolConfiguration(scale: .large)
//        let image = UIImage(systemName: "photo", withConfiguration: conf) //??
//        imageView.image = image //??
        imageView.image = nil
        imageView.backgroundColor = UIColor.lightGray //??
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, UInt>(collectionView: self.newsFeedCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? in
            
            
            let count = collectionView.numberOfItems(inSection: 0)
            if count - 1 == indexPath.row {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsButtonCell", for: indexPath) as? NewsButtonCell
                
                return cell
            }
            
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreliminaryNewsCell.kIdentifier, for: indexPath) as? PreliminaryNewsCell else {
                fatalError() //??
            }
            
          
            
            var newsItem: NewsItem? //??
            NewsStorage.shared.lock.with {
                newsItem = NewsStorage.shared.news[identifier]
            }
            
            if newsItem == nil { //??
                return cell
            }
            
            cell.headerLabel.text = newsItem!.title
            
            guard let url = newsItem!.titleImageUrl else {
                self.setDefaultImage(for: cell.imageView)
                return cell
            }
            
            self.setDefaultImage(for: cell.imageView)//??
            
            ImageCache.publicCache.load(url: url, item: newsItem!) { (fetchedItem, image, cached) in
                if cached {
                    cell.imageView.image = image
                    cell.imageView.contentMode = .scaleAspectFill
                } else {
                    if image != nil  {
                        var updatedSnapshot = self.dataSource.snapshot()
                        updatedSnapshot.reloadItems([fetchedItem.id])
                        self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            
            return cell
        }
        
        //??use collectionView.dequeueConfiguredReusableCell(using: cellRegistration
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, UInt>()
        snapshot.appendSections([.main])
        
        NewsStorage.shared.lock.with {
            let keys = [UInt](NewsStorage.shared.news.keys)
            snapshot.appendItems(keys) //?? hash specifi news with id //?? keys sorted
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
//        snapshot.reloadItems() //??
//        snapshot.deleteItems()
    }
    
    private func configureLayout() {
        self.newsFeedCollectionView.collectionViewLayout = createRowLayout()
    }
    
    private func createRowLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))

            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0)
            
            let size = layoutEnvironment.container.contentSize
            let w = 1.7 * size.height //??
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(w), heightDimension: .fractionalHeight(1.0)), subitems: [item]) //?? 0,33 оптимизация для альбомной ориентации //.fractionalWidth(0.48
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            
            section.orthogonalScrollingBehavior = .continuous //??
            
            return section
        }
        
        return layout
    }
}
