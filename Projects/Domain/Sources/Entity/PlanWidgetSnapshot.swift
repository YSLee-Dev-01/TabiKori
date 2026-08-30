//
//  PlanWidgetSnapshot.swift
//  Domain
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct PlanWidgetSnapshot: Codable, Equatable, Sendable {
    public let updatedAt: Date
    public let plans: [PlanWidgetSnapshotItem]

    public init(updatedAt: Date, plans: [PlanWidgetSnapshotItem]) {
        self.updatedAt = updatedAt
        self.plans = plans
    }

    /// `date` 기준으로 위젯에 표시할 일정을 고른다: 진행 중인 일정 우선, 없으면 가장 가까운 미래 일정
    public func plan(on date: Date) -> PlanWidgetSnapshotItem? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        let ongoing = self.plans
            .filter { calendar.startOfDay(for: $0.startDate) <= today && today <= calendar.startOfDay(for: $0.endDate) }
            .sorted { $0.startDate < $1.startDate }
        if let first = ongoing.first { return first }

        let upcoming = self.plans
            .filter { calendar.startOfDay(for: $0.startDate) > today }
            .sorted { $0.startDate < $1.startDate }
        return upcoming.first
    }
}

public struct PlanWidgetSnapshotItem: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let emoji: String
    public let regionTitle: String
    public let startDate: Date
    public let endDate: Date

    public init(id: UUID, title: String, emoji: String, regionTitle: String, startDate: Date, endDate: Date) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.regionTitle = regionTitle
        self.startDate = startDate
        self.endDate = endDate
    }

    public var dayCount: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.startDate)
        let end = calendar.startOfDay(for: self.endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }

    /// `date` 기준 이 일정의 진행 일자 인덱스(0-based), 범위 밖이면 nil
    public func dayIndex(on date: Date) -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.startDate)
        let target = calendar.startOfDay(for: date)
        let offset = calendar.dateComponents([.day], from: start, to: target).day ?? -1
        guard offset >= 0, offset < self.dayCount else { return nil }
        return offset
    }

    /// `date` 기준 시작일까지 남은 일수, 이미 시작했으면 0
    public func daysUntilStart(on date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.startDate)
        let target = calendar.startOfDay(for: date)
        let offset = calendar.dateComponents([.day], from: target, to: start).day ?? 0
        return max(offset, 0)
    }
}
