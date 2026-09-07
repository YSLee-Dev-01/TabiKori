//
//  FestivalUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum FestivalUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: FestivalUseCaseProtocol {
        TestFestivalUseCase()
    }
}
