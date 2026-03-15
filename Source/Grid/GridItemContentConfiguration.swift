//
//  GridItemContentConfiguration.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/12/26.
//

import UIKit

class GridItemContentView: RemoteImageContentView {
    private struct Constants {
        static let kStackEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        static let kContentViewCornerRadius: CGFloat = 20
        static let kStackSpacing: CGFloat = 6
        static let kContentViewInitFrame = CGRect(x: 0, y: 0, width: 100, height: 160)
        static let kImageViewHeightMultiplier: CGFloat = 0.5
    }

    private var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .label
            titleLabel.font = .boldSystemFont(ofSize: 18)
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.textAlignment = .left
        }
    }

    private var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.font = .systemFont(ofSize: 14)
            subtitleLabel.numberOfLines = 0
            subtitleLabel.lineBreakMode = .byTruncatingTail
            subtitleLabel.textAlignment = .left
        }
    }
    
    private var dateLabel: InsetLabel! {
        didSet {
            dateLabel.edgeInsets = Constants.kStackEdgeInsets
            dateLabel.textColor = .secondaryLabel
            dateLabel.font = .systemFont(ofSize: 14)
            dateLabel.numberOfLines = 1
            dateLabel.textAlignment = .left
        }
    }

    init(configuration: GridItemContentConfiguration) {
        super.init(frame: Constants.kContentViewInitFrame)
        self.setupUI()
        self.apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func customConstraints(for imageView: UIImageView) -> [NSLayoutConstraint]? {
        return [
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: Constants.kImageViewHeightMultiplier)
        ]
    }

    override func setupUI() {
        super.setupUI()
        self.layer.cornerRadius = Constants.kContentViewCornerRadius
        self.layer.masksToBounds = true
        self.backgroundColor = .secondarySystemBackground

        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true

        self.titleLabel = UILabel(frame: .zero)
        self.subtitleLabel = UILabel(frame: .zero)

        self.dateLabel = InsetLabel(frame: .zero)
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.dateLabel)

        let vstack = UIStackView(arrangedSubviews:[self.titleLabel, self.subtitleLabel])
        vstack.translatesAutoresizingMaskIntoConstraints = false
        vstack.axis = .vertical
        vstack.spacing = Constants.kStackSpacing
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = Constants.kStackEdgeInsets
        vstack.distribution = .fill
        self.addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: Constants.kStackSpacing),
            vstack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            self.dateLabel.topAnchor.constraint(greaterThanOrEqualTo: vstack.bottomAnchor, constant: Constants.kStackSpacing),
            self.dateLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.dateLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.dateLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.kStackSpacing)
        ])
    }

    @discardableResult
    override func apply(configuration: any RemoteImageContentInterface) -> Bool {
        if super.apply(configuration: configuration),
           let config = configuration as? GridItemContentConfiguration {
            self.titleLabel.text = config.title
            self.subtitleLabel.text = config.subtitle
            self.dateLabel.text = config.date?.localizedNumericDate()

            return true
        }

        return false
    }
}

struct GridItemContentConfiguration: RemoteImageContentInterface {
    var imageUrl: URL?
    var load: ImageLoadState = .none
    var title: String?
    var subtitle: String?
    var date: Date?

    func makeContentView() -> UIView & UIContentView {
        return GridItemContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> GridItemContentConfiguration {
        return self
    }

    func equalTo(value: (any RemoteImageContentInterface)?) -> Bool {
        let config = value as? GridItemContentConfiguration
        return self.imageUrl == config?.imageUrl &&
               self.title == config?.title &&
               self.subtitle == config?.subtitle &&
               self.date == config?.date
    }
}
