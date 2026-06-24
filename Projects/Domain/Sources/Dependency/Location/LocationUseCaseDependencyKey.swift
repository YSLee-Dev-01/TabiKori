//
//  LocationUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

enum LocationUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: LocationUseCaseProtocol {
        TestLocationUseCase()
    }
}
