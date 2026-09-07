//
//  TabiWebView.swift
//  DesignSystem
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WebKit

/// 지정한 URL을 앱 내에서 표시하기 위한 공용 `WKWebView` wrapper
public struct TabiWebView: UIViewRepresentable {

    private let urlString: String
    private let reloadTrigger: Int
    private let onLoadFailed: () -> Void

    public init(urlString: String, reloadTrigger: Int, onLoadFailed: @escaping () -> Void) {
        self.urlString = urlString
        self.reloadTrigger = reloadTrigger
        self.onLoadFailed = onLoadFailed
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: self.urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastReloadTrigger != self.reloadTrigger else { return }
        context.coordinator.lastReloadTrigger = self.reloadTrigger
        if let url = URL(string: self.urlString) {
            uiView.load(URLRequest(url: url))
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onLoadFailed: self.onLoadFailed)
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {

        var lastReloadTrigger = 0
        private let onLoadFailed: () -> Void

        init(onLoadFailed: @escaping () -> Void) {
            self.onLoadFailed = onLoadFailed
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.onLoadFailed()
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            self.onLoadFailed()
        }
    }
}
