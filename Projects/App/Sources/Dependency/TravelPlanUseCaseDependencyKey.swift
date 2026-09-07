//
//  TravelPlanUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension TravelPlanUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: TravelPlanUseCaseProtocol {
        TravelPlanUseCase(repository: TravelPlanRepository())
    }
}
