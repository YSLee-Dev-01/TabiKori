//
//  TouristSpotUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum TouristSpotUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: TouristSpotUseCaseProtocol {
        TestTouristSpotUseCase()
    }
}
