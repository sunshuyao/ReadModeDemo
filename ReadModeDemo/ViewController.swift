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
    @IBOutlet weak var copyItem: UIBarButtonItem!
    @IBOutlet weak var checkItem: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        readModeBtn.isEnabled = false
        if let config = setupConfig() {
            webView = WKWebView(frame: self.view.bounds, configuration: config)
            if let webView = webView {
                webView.navigationDelegate = self
                webView.load(URLRequest(url: URL(string: "https://xw.qq.com/")!))
                self.view.addSubview(webView)
            }
            readView = WKWebView(frame: self.view.bounds)
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
        
        copyItem.target = self
        copyItem.action = #selector(handleCopy)
        
        checkItem.target = self
        checkItem.action = #selector(isReadModeEnable)
    }
    @objc func handleCopy() {
        //UIPasteboard.general.string = String(describing: webView?.backForwardList.currentItem?.url)
        UIPasteboard.general.url = webView?.backForwardList.currentItem?.url
    }
    @objc func handleGoBack() {
        if let canGoBack = webView?.canGoBack, canGoBack {
            webView?.goBack()
        }
    }
    @objc func handleClick() {
        //go out
        if readView?.alpha == 1 {
            readView?.alpha = 0
            readView?.isUserInteractionEnabled = false
            readModeBtn.title = "阅读模式"
            goBackItem.isEnabled = true
            readModeBtn.isEnabled = false
            checkItem.isEnabled = true
            return
        }
        //go in
        if let webView = webView {
            webView.evaluateJavaScript(" (function(){var html = readability.mytest();var outHtml = html.outerHTML;return outHtml;})();", completionHandler: { (result, error) in
                if let result = result as? String {
                    print(result)
                    //index2.html
                    let indexPath = Bundle.main.path(forResource: "index2", ofType: "html")
                    var indexHTML = try! String(contentsOfFile: indexPath!, encoding: String.Encoding.utf8)
                    indexHTML = indexHTML.replacingOccurrences(of: "<!---->", with: result)
                    self.readView?.loadHTMLString(indexHTML, baseURL: self.webView?.url)
                    self.readView?.alpha = 1
                    self.readView?.isUserInteractionEnabled = true
                    self.readModeBtn.title = "退出阅读模式"
                    self.readModeBtn.isEnabled = true
                    self.goBackItem.isEnabled = false
                    self.checkItem.isEnabled = false
                }
            })
        }
    }
    func setupConfig() -> WKWebViewConfiguration? {
        if let readerJsPath = Bundle.main.path(forResource: "reader", ofType: "js") {
            let readerJs = try! String(contentsOfFile: readerJsPath, encoding: .utf8)
            let readerUserScript = WKUserScript(source: readerJs, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            let readerContentController = WKUserContentController()
            readerContentController.addUserScript(readerUserScript)
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
    @objc
    func isReadModeEnable() {
        webView?.evaluateJavaScript("readability.isEnableReader();", completionHandler: {(result, error) in
            if let enable = result as? NSNumber, enable.intValue == 1 {
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
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//
//        decisionHandler(.allow)
//    }
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        if webView === self.webView {
//            readModeBtn.isEnabled = false
//            isReadModeEnable()
//        }
//    }
}

