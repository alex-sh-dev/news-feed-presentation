//
//  ImageCollectionViewCell.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/16/26.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    lazy private(set) var imageConfigurationState = ImageCellConfigurationState(traitCollection: configurationState.traitCollection)

    func updateConfiguration(using state: ImageCellConfigurationState) {
        if !state.setUpdateImageIfNeeded {
            return
        }

        if let config = self.contentConfiguration as? (any RemoteImageContentInterface),
           config.load == .canceled {
            self.setNeedsUpdateConfiguration()
        }
    }
}
