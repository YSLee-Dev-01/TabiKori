//
//  TestImageCacheUseCase.swift
//  Domain
//
//  Created by 이윤수 on 9/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestImageCacheUseCase: ImageCacheUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var clearCacheCalled: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func clearCache() async {
        self.clearCacheCalled = true
    }
}
