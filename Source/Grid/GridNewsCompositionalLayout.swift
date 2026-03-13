//
//  GridNewsCompositionalLayout.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit

class GridNewsCompositionalLayout: UICollectionViewCompositionalLayout{
    private struct Constants {
        static let kItemMinWidth: CGFloat = 250
        static let kMinWItemCount: UInt = 3
        static let kMinHItemCount: UInt = 2
        static let kItemHeightFactor: CGFloat = 1.3
        static let kItemFracHeight = 1.0
        static let kGroupFracWidth = 1.0
        static let kItemContentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: 8, bottom: 8, trailing: 8)
    }

    override init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        super.init(sectionProvider: sectionProvider)
    }

    convenience init() {
        self.init() {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let contentSize = layoutEnvironment.container.contentSize
            let itemWCount: UInt = max(UInt(contentSize.width / Constants.kItemMinWidth),
                                       Constants.kMinWItemCount)
            let calcWidth = contentSize.width / CGFloat(itemWCount)
            let newHeight = min(calcWidth * Constants.kItemHeightFactor,
                                contentSize.height / CGFloat(Constants.kMinHItemCount))

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1 / CGFloat(itemWCount)), heightDimension: .fractionalHeight(Constants.kItemFracHeight))

            var items: [NSCollectionLayoutItem] = []
            for _ in 0..<itemWCount {
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = Constants.kItemContentInsets
                items.append(item)
            }

            // TODO: refactor (solution for iOS 17 +)
            // https://stackoverflow.com/questions/70914299/uicollectionviewcompositionallayout-how-to-expand-cells-to-same-height
            // https://developer.apple.com/documentation/uikit/nscollectionlayoutdimension/uniformacrosssiblings(estimate:)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(Constants.kGroupFracWidth), heightDimension: .absolute(newHeight))
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: items)

            let section = NSCollectionLayoutSection(group: containerGroup)
            return section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
