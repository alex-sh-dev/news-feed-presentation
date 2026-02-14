//
//  FullNewsTextRequester.swift
//  NewsFeedPresentation
//
//  Created by dev on 2/14/26.
//

import UIKit
import WebKit
import Combine

class FullNewsTextRequester: NSObject, WKNavigationDelegate {
    private struct Consts {
        static let kNewsTextJSCode = "document.getElementsByClassName('news-text')[0].outerText"
        static let kAttemptCount = 6
        static let kRequestDelaySec: TimeInterval = 0.5
    }
    
    let newsTextReceived = PassthroughSubject<String?, Never>()
    
    private var webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
    private var timer: Timer?
    private var timerCount = 0
    
    override init() {
        super.init()
        self.webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        self.webView.navigationDelegate = self
    }
    
    func start(for url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timerCount = 0
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: Consts.kRequestDelaySec, repeats: true) {
            timer in
            
            self.webView.evaluateJavaScript(Consts.kNewsTextJSCode, completionHandler: { result, error in
                if let dataText = result as? String, !dataText.isEmpty {
                    self.newsTextReceived.send(dataText)
                    timer.invalidate()
                    self.timerCount = 0
                } else {
                    self.timerCount += 1
                }
                if self.timerCount > Consts.kAttemptCount {
                    self.newsTextReceived.send(nil)
                    timer.invalidate()
                    self.timerCount = 0
                }
            })
        }
    }
}
