//
//  NaverMapUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import UIKit

import ComposableArchitecture
import Core
import Domain

extension NaverMapUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: NaverMapUseCaseProtocol {
        LiveNaverMapUseCase()
    }
}

// MARK: - Live Implementation

private struct LiveNaverMapUseCase: NaverMapUseCaseProtocol {
    func searchPlace(query: String) async {
        var components = URLComponents()
        components.scheme = "nmap"
        components.host = "search"
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "appname", value: self.appName)
        ]
        guard let url = components.url else {
            AppLogger.core.log(.error, "네이버 지도 통합검색 URL 생성 실패: query=\(query)")
            return
        }
        await self.open(deepLink: url)
    }

    func routeToDestination(coordinate: Coordinate, destinationName: String) async {
        var components = URLComponents()
        components.scheme = "nmap"
        components.host = "route"
        components.path = "/public"
        components.queryItems = [
            URLQueryItem(name: "dlat", value: String(coordinate.latitude)),
            URLQueryItem(name: "dlng", value: String(coordinate.longitude)),
            URLQueryItem(name: "dname", value: destinationName),
            URLQueryItem(name: "appname", value: self.appName)
        ]
        guard let url = components.url else {
            AppLogger.core.log(.error, "네이버 지도 대중교통 길찾기 URL 생성 실패: name=\(destinationName)")
            return
        }
        await self.open(deepLink: url)
    }
}

// MARK: - Method

private extension LiveNaverMapUseCase {
    static let appStoreURLString = "http://itunes.apple.com/app/id311867728?mt=8"

    var appName: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    @MainActor
    func open(deepLink: URL) async {
        guard UIApplication.shared.canOpenURL(deepLink) else {
            await self.openAppStore()
            return
        }
        let isOpened = await self.open(url: deepLink)
        if isOpened == false {
            AppLogger.core.log(.error, "네이버 지도 딥링크 실행 실패: \(deepLink.absoluteString)")
        }
    }

    @MainActor
    func openAppStore() async {
        guard let url = URL(string: Self.appStoreURLString) else {
            AppLogger.core.log(.error, "네이버 지도 App Store URL 생성 실패")
            return
        }
        let isOpened = await self.open(url: url)
        if isOpened == false {
            AppLogger.core.log(.error, "네이버 지도 App Store 이동 실패: \(url.absoluteString)")
        }
    }

    @MainActor
    func open(url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { isSuccess in
                continuation.resume(returning: isSuccess)
            }
        }
    }
}
