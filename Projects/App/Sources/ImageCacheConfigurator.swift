//
//  ImageCacheConfigurator.swift
//  App
//
//  Created by 이윤수 on 9/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Kingfisher

enum ImageCacheConfigurator {

    // MARK: - Method

    static func configure() {
        let cache = ImageCache.default

        cache.memoryStorage.config.expiration = .seconds(60 * 60)

        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
    }
}
