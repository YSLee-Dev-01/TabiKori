//
//  OnboardingUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 6/15/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension OnboardingUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: OnboardingUseCaseProtocol {
        OnboardingUseCase(repository: OnboardingRepository())
    }
}
