//
//  PreviewNewsCompositionalLayout.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/11/26.
//

import UIKit

class PreviewNewsCompositionalLayout: UICollectionViewCompositionalLayout {
    private struct Constants {
        static let kItemFracWidth = 1.0
        static let kItemFracHeight = 1.0
        static let kItemContInsetsLead = 5.0
        static let kGroupWidthFactor = 1.7
        static let kGroupFracHeight = 1.0
    }
    
    override init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        super.init(sectionProvider: sectionProvider)
    }

    convenience init() {
        self.init() {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kItemFracWidth), heightDimension: .fractionalHeight(Constants.kItemFracHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            var itemContInsets = NSDirectionalEdgeInsets.zero
            itemContInsets.leading = Constants.kItemContInsetsLead
            item.contentInsets = itemContInsets
            
            let size = layoutEnvironment.container.contentSize
            let w = Constants.kGroupWidthFactor * size.height
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(w), heightDimension: .fractionalHeight(Constants.kGroupFracHeight))
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .continuous
            
            return section
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
