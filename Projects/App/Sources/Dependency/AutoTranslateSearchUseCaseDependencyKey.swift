//
//  AutoTranslateSearchUseCaseDependencyKey.swift
//  App
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension AutoTranslateSearchUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: AutoTranslateSearchUseCaseProtocol {
        AutoTranslateSearchUseCase(repository: AutoTranslateSearchRepository())
    }
}
