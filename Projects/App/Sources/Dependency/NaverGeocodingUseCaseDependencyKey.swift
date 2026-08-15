//
//  NaverGeocodingUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension NaverGeocodingUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: NaverGeocodingUseCaseProtocol {
        NaverGeocodingUseCase(repository: NaverGeocodingRepository())
    }
}
