//
//  TravelItemUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension TravelItemUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: TravelItemUseCaseProtocol {
        TravelItemUseCase(
            travelItemRepository: TravelItemRepository(),
            travelPlanItemRepository: TravelPlanItemRepository()
        )
    }
}
