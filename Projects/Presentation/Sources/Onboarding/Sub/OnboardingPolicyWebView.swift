//
//  OnboardingPolicyWebView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WebKit

import Resource

/// 개인정보처리방침 페이지를 앱 내에서 표시하기 위한 `WKWebView` wrapper.
/// 온보딩 전용이며 재사용 가능성이 낮아 DesignSystem이 아닌 Onboarding 화면 내부에 위치한다
struct OnboardingPolicyWebView: UIViewRepresentable {

    let reloadTrigger: Int
    let onLoadFailed: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: TabiURL.privacyPolicy) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastReloadTrigger != self.reloadTrigger else { return }
        context.coordinator.lastReloadTrigger = self.reloadTrigger
        if let url = URL(string: TabiURL.privacyPolicy) {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadFailed: self.onLoadFailed)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {

        var lastReloadTrigger = 0
        private let onLoadFailed: () -> Void

        init(onLoadFailed: @escaping () -> Void) {
            self.onLoadFailed = onLoadFailed
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            self.onLoadFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            self.onLoadFailed()
        }
    }
}
