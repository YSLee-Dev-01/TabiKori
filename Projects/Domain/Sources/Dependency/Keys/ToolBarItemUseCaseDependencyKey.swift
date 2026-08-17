//
//  ToolBarItemUseCaseDependencyKey.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum ToolBarItemUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: ToolBarItemUseCaseProtocol {
        TestToolBarItemUseCase()
    }
}
