//
//  HomeSheetAnnounceUseCaseDependencyKey.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum HomeSheetAnnounceUseCaseDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: HomeSheetAnnounceUseCaseProtocol {
        TestHomeSheetAnnounceUseCase()
    }
}
