//
//  SettingInfoUseCaseDependencyKey.swift
//  Domain
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum SettingInfoUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: SettingInfoUseCaseProtocol {
        TestSettingInfoUseCase()
    }
}
