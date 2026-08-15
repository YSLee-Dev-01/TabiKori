//
//  FestivalUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension FestivalUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: FestivalUseCaseProtocol {
        FestivalUseCase(repository: FestivalRepository())
    }
}
