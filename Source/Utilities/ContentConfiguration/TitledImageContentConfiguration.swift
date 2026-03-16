//
//  TitledImageContentConfiguration.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/11/26.
//

import UIKit

class TitledImageContentView: RemoteImageContentView {
    private struct Constants {
        static let kTitleLabelEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 4, right: 6)
        static let kTitleLabelHeightMultiplier: CGFloat = 0.5
        static let kContentViewCornerRadius: CGFloat = 8
    }

    private var titleLabel: InsetLabel! {
        didSet {
            titleLabel.edgeInsets = Constants.kTitleLabelEdgeInsets
            titleLabel.textColor = .white
            titleLabel.font = .boldSystemFont(ofSize: 17)
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.textAlignment = .left
        }
    }

    init(configuration: TitledImageContentConfiguration) {
        super.init(frame: .zero)
        self.setupUI()
        self.apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        self.layer.cornerRadius = Constants.kContentViewCornerRadius
        self.layer.masksToBounds = true
        self.titleLabel = InsetLabel(frame: .zero)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.titleLabel.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: Constants.kTitleLabelHeightMultiplier)
        ])
    }

    @discardableResult
    override func apply(configuration: any RemoteImageContentInterface) -> Bool {
        if super.apply(configuration: configuration),
           let config = configuration as? TitledImageContentConfiguration {
            self.titleLabel.text = config.title

            return true
        }

        return false
    }
}

struct TitledImageContentConfiguration: RemoteImageContentInterface {
    var imageUrl: URL?
    var load: ImageLoadState = .none
    var title: String?

    func makeContentView() -> UIView & UIContentView {
        return TitledImageContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> TitledImageContentConfiguration {
        return self
    }

    func equalTo(value: (any RemoteImageContentInterface)?) -> Bool {
        let config = value as? TitledImageContentConfiguration
        return self.imageUrl == config?.imageUrl && self.title == config?.title
    }
}
