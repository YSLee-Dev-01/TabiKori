//
//  DependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum OnboardingUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: OnboardingUseCaseProtocol {
        TestOnboardingUseCase()
    }
}
