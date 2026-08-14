//
//  TravelPlanShareUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum TravelPlanShareUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: TravelPlanShareUseCaseProtocol {
        TestTravelPlanShareUseCase()
    }
}
