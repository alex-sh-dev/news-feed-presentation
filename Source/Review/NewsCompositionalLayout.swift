//
//  NewsCompositionalLayout.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

class NewsCompositionalLayout: UICollectionViewCompositionalLayout {
    
    private struct Constants {
        //?? может что-то удалить?
        static let kItemFracWidth = 1.0
        static let kItemFracHeight = 1.0
        static let kGroupFracWidth = 1.0
        static let kGroupFracHeight = 1.0 //??
        static let kItemContInsetsBottom = 20.0 //??
    }
    
    override init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        super.init(sectionProvider: sectionProvider)
    }
    
    convenience init() {
        self.init() {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let size = layoutEnvironment.container.contentSize
            let h = size.width / 1.77 //??
            
            let value = 100.0//?? 92 сумма всех высот
            
            let firstItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kItemFracWidth), heightDimension: .estimated(value)) //??
            let firstItem = NSCollectionLayoutItem(layoutSize: firstItemSize)
            
            let secondItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kItemFracWidth), heightDimension: .absolute(h))
            let secondItem = NSCollectionLayoutItem(layoutSize: secondItemSize)
            
            var secondItemContInsets = NSDirectionalEdgeInsets.zero
            secondItemContInsets.bottom = Constants.kItemContInsetsBottom
            secondItem.contentInsets = secondItemContInsets//??

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kGroupFracWidth), heightDimension:.estimated(value)) //??
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [firstItem, secondItem])

            let section = NSCollectionLayoutSection(group: group)
          
            return section
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
