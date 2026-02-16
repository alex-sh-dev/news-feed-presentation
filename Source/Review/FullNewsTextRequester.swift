//
//  FullNewsTextRequester.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/14/26.
//

import UIKit
import WebKit

class FullNewsTextRequester: NSObject, WKNavigationDelegate {
    private struct Consts {
        static let kNewsTextJSCode = "document.getElementsByClassName('news-text')[0].outerText"
        static let kAttemptCount = 6
        static let kRequestDelaySec: TimeInterval = 0.5
    }
    
    typealias ItemId = Any
    var completionHandler: ((ItemId, String?) -> Void)?
    
    private var webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
    private var timer: Timer?
    private var timerCount = 0
    private var id: ItemId = 0
    
    override init() {
        super.init()
        self.webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        self.webView.navigationDelegate = self
    }
    
    deinit {
        easyLog(String(describing: self))
    }
    
    func start(for url: URL, with id: ItemId, completionHandler: @escaping ((ItemId, String?) -> Void)) {
        self.id = id
        self.completionHandler = completionHandler
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.timer != nil {
            self.timer!.invalidate()
            self.timerCount = 0
            self.completionHandler?(self.id, nil)
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: Consts.kRequestDelaySec, repeats: true) {
            [weak self] timer in
            self?.webView.evaluateJavaScript(Consts.kNewsTextJSCode, completionHandler: { [weak self]
                result, error in
                guard let self = self else { return }
                let stopTimer: (String?) -> Void = {
                    text in
                    self.completionHandler?(self.id, text)
                    timer.invalidate()
                    self.timerCount = 0
                }
                if let dataText = result as? String, !dataText.isEmpty {
                    stopTimer(dataText)
                } else {
                    self.timerCount += 1
                }
                if self.timerCount > Consts.kAttemptCount {
                    stopTimer(nil)
                }
            })
        }
    }
}
