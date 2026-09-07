//
//  NaverMapUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 7/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum NaverMapUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: NaverMapUseCaseProtocol {
        TestNaverMapUseCase()
    }
}
