//
//  AnalyticsCenterProtocol.swift
//  Domain
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 분석 이벤트를 기록하는 센터
public protocol AnalyticsCenterProtocol: Sendable {
    /// 이벤트를 기록한다
    func log(_ event: AnalyticsEvent)
}
