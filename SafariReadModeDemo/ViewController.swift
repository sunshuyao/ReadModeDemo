//
//  ViewController.swift
//  SafariReadModeDemo
//
//  Created by Sun,Shuyao on 2018/3/26.
//  Copyright © 2018年 Sun,Shuyao. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController {
    var webView: WKWebView?
    var readView: WKWebView?
    var readerModeAvailable = false {
        didSet {
            if readerModeAvailable {
                readModeBtn.isEnabled = true
            } else {
                readModeBtn.isEnabled = false
            }
        }
    }

    
    var outerArticle:String?
    var atitle:String?
    var nextPageURL:String?
    var innerArticle:String?
    @IBOutlet weak var readModeBtn: UIBarButtonItem!
    @IBOutlet weak var goBackItem: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        readModeBtn.isEnabled = false
        if let config = setupConfig() {
            webView = WKWebView(frame: self.view.bounds, configuration: config)
            if let webView = webView {
                webView.navigationDelegate = self
                webView.load(URLRequest(url: URL(string: "https://news.sina.cn")!))
                self.view.addSubview(webView)
            }
            readView = WKWebView(frame: self.view.bounds, configuration: config)
            if let readView = readView {
                readView.navigationDelegate = self
                readView.isUserInteractionEnabled = false
                readView.alpha = 0
                self.view.addSubview(readView)
            }
        }
        readModeBtn.target = self
        readModeBtn.action = #selector(handleClick)
        
        goBackItem.target = self
        goBackItem.action = #selector(handleGoBack)
    }
    @objc func handleGoBack() {
        if let canGoBack = webView?.canGoBack, canGoBack {
            webView?.goBack()
        }
    }
    @objc func handleClick() {
        //quite read mode
        if readView?.alpha == 1 {
            readView?.alpha = 0
            readView?.isUserInteractionEnabled = false
            goBackItem.isEnabled = true
            readModeBtn.title = "阅读模式"
            return
        }
        //go to read mode
        if let webView = webView {
            webView.evaluateJavaScript(" (function(){var article = ReaderJS.createPageFromNode(ReaderArticleFinderJS.adoptableArticle());var title = ReaderArticleFinderJS.articleTitle();var nextPage = ReaderArticleFinderJS.nextPageURL();var outerArticle = (article && article.outerHTML) || '';var innerArticle = (article && article.innerHTML) || '';title = title || '';nextPage = nextPage || '';if(!window['ssReaderModeResult']){ssReaderModeResult = [outerArticle, title, nextPage, escape(innerArticle)];}return ssReaderModeResult;})();", completionHandler: { (result, error) in
                if let result = result as? Array<String> {
                    self.outerArticle = result[0]
                    self.atitle = result[1]
                    self.nextPageURL = result[2]
                    self.innerArticle = result[3]
                    //index2.html
                    let indexPath = Bundle.main.path(forResource: "index2", ofType: "html")
                    var indexHTML = try! String(contentsOfFile: indexPath!, encoding: String.Encoding.utf8)
                    //title
                    indexHTML = indexHTML.replacingOccurrences(of: "Reader", with: self.atitle!, options: String.CompareOptions.literal, range: indexHTML.startIndex ..< indexHTML.index(indexHTML.startIndex, offsetBy: 300))
                    //article
                    let articlePosition = "<div id=\"article\" role=\"article\">"
                    let range = indexHTML.range(of: articlePosition)
                    indexHTML.insert(contentsOf: self.outerArticle!, at: (range?.upperBound)!)
                    //another title
                    indexHTML = indexHTML.replacingOccurrences(of: "<h1 class=\"title\">undefined</h1>", with: "<h1 class=\"title\">\(self.atitle!)</h1>", options: String.CompareOptions.literal, range: indexHTML.startIndex ..< indexHTML.endIndex)
                    indexHTML = indexHTML.replacingOccurrences(of: "<h1 class=\"title\"></h1>", with: "<h1 class=\"title\">\(self.atitle!)</h1>", options: String.CompareOptions.literal, range: indexHTML.startIndex ..< indexHTML.endIndex)
                    self.readView?.loadHTMLString(indexHTML, baseURL: self.webView?.url)
                    self.readView?.alpha = 1
                    self.readView?.isUserInteractionEnabled = true
                    self.goBackItem.isEnabled = false
                    self.readModeBtn.title = "退出阅读模式"
                }
            })
        }
    }
    func setupConfig() -> WKWebViewConfiguration? {
        if let readerJsPath = Bundle.main.path(forResource: "readerLoad", ofType: "js"),let checkJsPath = Bundle.main.path(forResource: "readerCheck", ofType: "js") {
            let readerJs = try! String(contentsOfFile: readerJsPath, encoding: .utf8)
            let readerUserScript = WKUserScript(source: readerJs, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            let checkJs = try! String(contentsOfFile: checkJsPath, encoding: .utf8)
            let checkUserScript = WKUserScript(source: checkJs, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            let readerContentController = WKUserContentController()
            readerContentController.addUserScript(readerUserScript)
            readerContentController.addUserScript(checkUserScript)
            readerContentController.add(self, name: "JSController")
            let config = WKWebViewConfiguration()
            config.userContentController = readerContentController
            return config
        }
        return nil
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func isReadModeEnable() {
        webView?.evaluateJavaScript("ReaderArticleFinderJS.isReaderModeAvailable();", completionHandler: {(result, error) in
            if result as? Bool == true {
                self.readerModeAvailable = true
                print("read available: yes")
            } else {
                self.readerModeAvailable = false
                print("read available: no")
            }
        })
    }
}

extension ViewController:WKScriptMessageHandler, WKNavigationDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        readModeBtn.isEnabled = false
        isReadModeEnable()
        decisionHandler(.allow)
    }
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//    }
    
}

