//
//  BookmarkUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum BookmarkUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: BookmarkUseCaseProtocol {
        TestBookmarkUseCase()
    }
}
