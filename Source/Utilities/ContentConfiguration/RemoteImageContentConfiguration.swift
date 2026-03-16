//
//  RemoteImageContentConfiguration.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/11/26.
//

import UIKit

class RemoteImageContentView: UIView, UIContentView {
    private(set) var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFill
        }
    }

    private var currentConfiguration: (any RemoteImageContentInterface)!
    var configuration: UIContentConfiguration {
        get { return currentConfiguration }
        set {
            if let newConfiguration = newValue as? (any RemoteImageContentInterface) {
                self.apply(configuration: newConfiguration)
            }
        }
    }

    init(configuration: RemoteImageContentConfiguration) {
        super.init(frame: .zero)
        self.setupUI()
        self.apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func customConstraints(for imageView: UIImageView) -> [NSLayoutConstraint]? {
        return nil
    }

    func setupUI() {
        self.imageView = UIImageView(frame: .zero)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.imageView)
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        if let constraints = self.customConstraints(for: self.imageView) {
            NSLayoutConstraint.activate(constraints)
            return
        }
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setDefaultImage() {
        self.imageView.image = nil
        self.imageView.backgroundColor = UIColor.lightGray
    }

    private func loadImage(url: URL) {
        self.currentConfiguration.load = .loadRequested
        ImageLoader.shared.load(url: url, beforeLoad: {
            [weak self] in
            self?.setDefaultImage()
        }) {
            [weak self] (fetchedUrl, image) in
            guard let self = self else { return }
            if fetchedUrl != self.currentConfiguration.imageUrl {
                self.currentConfiguration.load = .canceled
                return
            }

            if image != nil {
                self.imageView.image = image
                self.currentConfiguration.load = .loaded
            } else {
                self.currentConfiguration.load = .canceled
            }
        }
    }

    @discardableResult
    func apply(configuration: any RemoteImageContentInterface) -> Bool {
        let equalConfigs = configuration.equalTo(value: self.currentConfiguration)
        if equalConfigs, configuration.load == .canceled,
            let url = configuration.imageUrl {
            self.loadImage(url: url)
        }

        if equalConfigs { return false }

        self.currentConfiguration = configuration
        guard let url = configuration.imageUrl else {
            self.setDefaultImage()
            return true
        }

        self.loadImage(url: url)
        return true
    }
}

enum ImageLoadState {
    case none
    case loadRequested
    case loaded
    case canceled
}

protocol RemoteImageContentInterface: UIContentConfiguration, Hashable {
    var imageUrl: URL? { get set }
    var load: ImageLoadState { get set }
    func equalTo(value: (any RemoteImageContentInterface)?) -> Bool
}

struct RemoteImageContentConfiguration: RemoteImageContentInterface {
    var imageUrl: URL?
    var load: ImageLoadState = .none

    func makeContentView() -> UIView & UIContentView {
        return RemoteImageContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> RemoteImageContentConfiguration {
        return self
    }

    func equalTo(value: (any RemoteImageContentInterface)?) -> Bool {
        return self.imageUrl == value?.imageUrl
    }
}
