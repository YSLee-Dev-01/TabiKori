//
//  SearchHistoryUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension SearchHistoryUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: SearchHistoryUseCaseProtocol {
        SearchHistoryUseCase(repository: SearchHistoryRepository())
    }
}
