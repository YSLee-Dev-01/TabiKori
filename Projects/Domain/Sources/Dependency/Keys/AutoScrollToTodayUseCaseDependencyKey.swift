//
//  AutoScrollToTodayUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum AutoScrollToTodayUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: AutoScrollToTodayUseCaseProtocol {
        TestAutoScrollToTodayUseCase()
    }
}
