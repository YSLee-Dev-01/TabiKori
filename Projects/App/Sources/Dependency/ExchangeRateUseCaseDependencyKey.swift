//
//  ExchangeRateUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension ExchangeRateUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: ExchangeRateUseCaseProtocol {
        ExchangeRateUseCase(repository: ExchangeRateRepository())
    }
}
