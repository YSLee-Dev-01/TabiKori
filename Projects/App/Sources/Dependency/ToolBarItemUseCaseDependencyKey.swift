//
//  ToolBarItemUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension ToolBarItemUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: ToolBarItemUseCaseProtocol {
        ToolBarItemUseCase(
            toolBarItemRepository: ToolBarItemRepository(),
            toolBarPlanItemRepository: ToolBarPlanItemRepository()
        )
    }
}
