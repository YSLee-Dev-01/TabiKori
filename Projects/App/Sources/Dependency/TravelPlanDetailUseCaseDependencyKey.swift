//
//  TravelPlanDetailUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension TravelPlanDetailUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: TravelPlanDetailUseCaseProtocol {
        TravelPlanDetailUseCase(repository: TravelPlanDetailRepository())
    }
}
