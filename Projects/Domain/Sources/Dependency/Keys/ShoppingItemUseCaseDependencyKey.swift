//
//  ShoppingItemUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ShoppingItemUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ShoppingItemUseCaseProtocol {
        TestShoppingItemUseCase()
    }
}
