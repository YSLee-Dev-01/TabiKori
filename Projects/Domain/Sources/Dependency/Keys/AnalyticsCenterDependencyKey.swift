//
//  AnalyticsCenterDependencyKey.swift
//  Domain
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

public enum AnalyticsCenterDependencyKey: TestDependencyKey, Sendable {
    public static var testValue: AnalyticsCenterProtocol {
        TestAnalyticsCenter()
    }
}
