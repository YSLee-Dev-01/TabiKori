//
//  TravelPlanShareUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

extension TravelPlanShareUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: TravelPlanShareUseCaseProtocol {
        TravelPlanShareUseCase()
    }
}
