//
//  ShoppingPlanItemUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ShoppingPlanItemUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ShoppingPlanItemUseCaseProtocol {
        TestShoppingPlanItemUseCase()
    }
}
