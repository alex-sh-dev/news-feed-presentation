//
//  ImageCellConfigurationState.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/16/26.
//

import UIKit

struct ImageCellConfigurationState : UIConfigurationState, Hashable {
    var traitCollection: UITraitCollection
    var setUpdateImageIfNeeded: Bool = true

    private var customStates: [UIConfigurationStateCustomKey: AnyHashable?] = [:]

    init(traitCollection: UITraitCollection) {
        self.traitCollection = traitCollection
    }

    subscript(key: UIConfigurationStateCustomKey) -> AnyHashable? {
        get { self.customStates[key] ?? nil }
        set { self.customStates[key] = newValue }
    }
}
