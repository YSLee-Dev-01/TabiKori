//
//  HomeSheetAnnounceUseCaseDependencyKey.swift
//  App
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension HomeSheetAnnounceUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: HomeSheetAnnounceUseCaseProtocol {
        HomeSheetAnnounceUseCase(repository: HomeSheetAnnounceRepository())
    }
}
