//
//  AutoTranslateSearchUseCaseDependencyKey.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum AutoTranslateSearchUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: AutoTranslateSearchUseCaseProtocol {
        TestAutoTranslateSearchUseCase()
    }
}
