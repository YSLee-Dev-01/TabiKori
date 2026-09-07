//
//  ShoppingPlanItemUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension ShoppingPlanItemUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: ShoppingPlanItemUseCaseProtocol {
        ShoppingPlanItemUseCase(
            shoppingPlanItemRepository: ShoppingPlanItemRepository()
        )
    }
}
