//
//  TravelPlan+.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain
import Resource

extension TravelPlan {
    static func dayCount(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }

    var dayCount: Int {
        Self.dayCount(startDate: self.startDate, endDate: self.endDate)
    }

    var dayDates: [Date] {
        let start = Calendar.current.startOfDay(for: self.startDate)
        return (0..<self.dayCount).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var periodTitle: String {
        "\(self.startDate.planPeriodDateTitle) 〜 \(self.endDate.planPeriodDateTitle)"
    }

    var displayEmoji: String {
        if let customEmoji = self.customEmoji, !customEmoji.isEmpty {
            return customEmoji
        }
        return self.region.emoji ?? "🗓️"
    }

    var displayRegionTitle: String {
        if self.region == .etc, let customRegionText = self.customRegionText, !customRegionText.isEmpty {
            return customRegionText
        }
        return self.region.jaTitle
    }

    /// 오늘 날짜가 이 일정의 dayDates 범위 안에 있으면 해당 일자 인덱스(0-based)를, 없으면 nil을 반환한다
    var todayDayIndex: Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.startDate)
        let today = calendar.startOfDay(for: Date())
        let offset = calendar.dateComponents([.day], from: start, to: today).day ?? -1
        guard self.dayDates.indices.contains(offset) else { return nil }
        return offset
    }

    var section: PlanSection {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: self.startDate)
        let end = calendar.startOfDay(for: self.endDate)

        if today >= start && today <= end { return .ongoing }
        if start > today { return .upcoming }
        return .past
    }
}
