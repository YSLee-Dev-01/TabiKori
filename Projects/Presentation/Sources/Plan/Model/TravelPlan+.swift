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
    var dayCount: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self.startDate)
        let end = calendar.startOfDay(for: self.endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }

    var dayChipTitles: [String] {
        (1...self.dayCount).map { Strings.Plan.dayChipTitle($0) }
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
