//
//  AutoScrollToTodayUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension AutoScrollToTodayUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: AutoScrollToTodayUseCaseProtocol {
        AutoScrollToTodayUseCase(repository: AutoScrollToTodayRepository())
    }
}
