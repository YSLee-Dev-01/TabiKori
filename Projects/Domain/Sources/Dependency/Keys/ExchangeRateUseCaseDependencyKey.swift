//
//  ExchangeRateUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ExchangeRateUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ExchangeRateUseCaseProtocol {
        TestExchangeRateUseCase()
    }
}
