//
//  TouristSpotUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension TouristSpotUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: TouristSpotUseCaseProtocol {
        TouristSpotUseCase(repository: TouristSpotRepository())
    }
}
