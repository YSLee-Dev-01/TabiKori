//
//  DataResetUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum DataResetUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: DataResetUseCaseProtocol {
        TestDataResetUseCase()
    }
}
