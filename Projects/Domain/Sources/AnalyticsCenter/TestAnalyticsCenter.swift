//
//  TestAnalyticsCenter.swift
//  Domain
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// TCA 의존성(testValue)용 테스트 더블 — 기록된 `AnalyticsEvent`들을 배열로 기록한다
public final class TestAnalyticsCenter: AnalyticsCenterProtocol, @unchecked Sendable {
    public var loggedEvents: [AnalyticsEvent] = []

    public init() {}

    public func log(_ event: AnalyticsEvent) {
        self.loggedEvents.append(event)
    }
}
