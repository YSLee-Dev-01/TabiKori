//
//  TestOnboardingUseCase.swift
//  Domain
//
//  Created by 이윤수 on 6/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

struct TestOnboardingUseCase: OnboardingUseCaseProtocol {
    func isCompleted() -> Bool {
        reportIssue("OnboardingUseCase.isCompleted 미주입")
        return false
    }

    func markAsCompleted() {
        reportIssue("OnboardingUseCase.markAsCompleted 미주입")
    }
}
