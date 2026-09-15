//
//  ImageCacheUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 9/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Kingfisher

extension ImageCacheUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: ImageCacheUseCaseProtocol {
        LiveImageCacheUseCase()
    }
}

// MARK: - Live Implementation

private struct LiveImageCacheUseCase: ImageCacheUseCaseProtocol {
    func clearCache() async {
        await ImageCache.default.clearCache()
    }
}
