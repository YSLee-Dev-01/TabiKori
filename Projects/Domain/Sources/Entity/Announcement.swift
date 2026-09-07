//
//  Announcement.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 팝업 공지 / 홈 화면 시트 공지 공용 엔티티
public struct Announcement: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let content: String
    public let startDate: Date
    public let endDate: Date?

    public init(id: String, title: String, subtitle: String, content: String, startDate: Date, endDate: Date?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Active Filtering

public extension Announcement {
    /// 오늘 날짜가 startDate ~ endDate(옵셔널) 범위에 포함되는지 여부 (일 단위 비교)
    func isActive(asOf date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: self.startDate)

        guard today >= start else { return false }
        guard let endDate else { return true }
        let end = calendar.startOfDay(for: endDate)
        return today <= end
    }

    /// 활성 항목 중 startDate 오름차순 첫 번째 항목 (팝업/홈 시트 공용 필터링 로직)
    static func firstActive(in announcements: [Announcement], asOf date: Date = Date()) -> Announcement? {
        return announcements
            .filter { $0.isActive(asOf: date) }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
}
