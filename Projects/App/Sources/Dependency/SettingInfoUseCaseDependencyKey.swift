//
//  SettingInfoUseCaseDependencyKey.swift
//  App
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Data

import ComposableArchitecture

extension SettingInfoUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: SettingInfoUseCaseProtocol {
        SettingInfoUseCase(repository: SettingInfoRepository())
    }
}
