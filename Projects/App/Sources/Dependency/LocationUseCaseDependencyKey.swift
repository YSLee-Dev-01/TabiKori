//
//  LocationUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension LocationUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: LocationUseCaseProtocol {
        LocationUseCase(repository: LocationRepository())
    }
}
