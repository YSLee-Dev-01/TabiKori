//
//  SearchHistoryUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum SearchHistoryUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: SearchHistoryUseCaseProtocol {
        TestSearchHistoryUseCase()
    }
}
