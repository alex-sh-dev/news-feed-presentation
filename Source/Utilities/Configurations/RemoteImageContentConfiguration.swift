//
//  RemoteImageContentConfiguration.swift
//  NewsFeedPresentation
//
//  Created by dev on 3/11/26.
//

import UIKit

class RemoteImageContentView: UIView, UIContentView {
    private var imageView: UIImageView! {
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

    func setupUI() {
        self.imageView = UIImageView(frame: .zero)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.imageView)
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
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

    @discardableResult
    func apply(configuration: any RemoteImageContentInterface) -> Bool {
        if configuration.equalTo(value: self.currentConfiguration) {
            return false
        }

        self.currentConfiguration = configuration
        guard let url = configuration.imageUrl else {
            self.setDefaultImage()
            return true
        }

        ImageLoader.shared.load(url: url, beforeLoad: {
            [weak self] in
            self?.setDefaultImage()
        }) {
            [weak self] (fetchedUrl, image, cached) in
            guard let self = self else { return }
            let equalUrls = fetchedUrl == self.currentConfiguration.imageUrl
            if (cached || equalUrls) && image != nil {
                self.imageView.image = image
            }
        }

        return true
    }
}

protocol RemoteImageContentInterface: UIContentConfiguration, Hashable {
    var imageUrl: URL? { get set }
    func equalTo(value: (any RemoteImageContentInterface)?) -> Bool
}

struct RemoteImageContentConfiguration: RemoteImageContentInterface {
    var imageUrl: URL?

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
