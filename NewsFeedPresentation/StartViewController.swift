//
//  ViewController.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/8/26.
//

import UIKit

class PreliminaryNewsCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    static let kIdentifier = String(describing: PreliminaryNewsCell.self)
    
    //?? register kIdentifier (remove from storyboard)
}

private enum Section {
    case main
}

class StartViewController: UIViewController {
    @IBOutlet weak var newsFeedCollectionView: UICollectionView! //?? rename? +preliminary
    private var dataSource: UICollectionViewDiffableDataSource<Section, UInt>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        configureLayout()
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, UInt>(collectionView: self.newsFeedCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UInt) -> UICollectionViewCell? in
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreliminaryNewsCell.kIdentifier, for: indexPath) as? PreliminaryNewsCell else {
                fatalError() //??
            }
            
            cell.backgroundColor = UIColor.lightGray
            cell.headerLabel.text = "\(identifier)"
            
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, UInt>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<10)) //?? hash specifi news with id
        dataSource.apply(snapshot, animatingDifferences: false)
//        snapshot.reloadItems() //?? когда загрузится изображение
//        snapshot.deleteItems()
    }
    
    private func configureLayout() {
        self.newsFeedCollectionView.collectionViewLayout = createRowLayout()
    }
    
    private func createRowLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment:NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
            
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1.0)), subitems: [item]) //?? 0,33 оптимизация для альбомной ориентации
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .continuous //??
            
            return section
        }
        
        return layout
    }
}
