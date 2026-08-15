//
//  TravelPlanDetailUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum TravelPlanDetailUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: TravelPlanDetailUseCaseProtocol {
        TestTravelPlanDetailUseCase()
    }
}
