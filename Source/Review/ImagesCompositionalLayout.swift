//
//  ImagesCompositionalLayout.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/12/26.
//

import UIKit

class ImagesCompositionalLayout: UICollectionViewCompositionalLayout {
    private struct Constants {
        static let kItemFracWidth = 1.0
        static let kItemFracHeight = 1.0
        static let kGroupFracWidth = 0.96
        static let kDefGroupFracWidth = 1.0
        static let kGroupFracHeight = 1.0
        //?? spacing, 99 for next image
    }
    
    override init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        super.init(sectionProvider: sectionProvider)
    }
    
    convenience init(groupSpacingAssigner: @escaping () -> Bool) {
        self.init {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let useGroupSpacing = groupSpacingAssigner()
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kItemFracWidth), heightDimension: .fractionalHeight(Constants.kItemFracHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupWidth = useGroupSpacing ? Constants.kGroupFracWidth : Constants.kDefGroupFracWidth
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(groupWidth), heightDimension: .fractionalHeight(Constants.kGroupFracHeight))
            
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .groupPaging
            
            section.interGroupSpacing =  useGroupSpacing ? 6 : 0 //?? to constants
            
            return section
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
