//
//  ShoppingItemUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension ShoppingItemUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: ShoppingItemUseCaseProtocol {
        ShoppingItemUseCase(repository: ShoppingItemRepository())
    }
}
