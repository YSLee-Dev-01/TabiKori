//
//  DataResetUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension DataResetUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: DataResetUseCaseProtocol {
        DataResetUseCase(
            bookmarkRepository: BookmarkRepository(),
            travelPlanRepository: TravelPlanRepository(),
            searchHistoryRepository: SearchHistoryRepository()
        )
    }
}
