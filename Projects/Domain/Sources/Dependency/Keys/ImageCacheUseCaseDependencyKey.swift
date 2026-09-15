//
//  ImageCacheUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 9/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ImageCacheUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ImageCacheUseCaseProtocol {
        TestImageCacheUseCase()
    }
}
