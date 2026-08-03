//
//  PlanDetailSpotRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailSpotRow: View {
    let spot: TravelPlanDetailSpot
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TabiLabel(title: self.spot.startTimeTitle, style: .captionMBold, color: .tabiTextSecondary)
                .frame(width: 40, alignment: .leading)

            self.timeline

            TabiCard {
                VStack(alignment: .leading, spacing: 6) {
                    TabiTag(self.spot.category.label, color: self.spot.category.color)
                    TabiLabel(title: self.spot.title, style: .bodyMBold, color: .tabiTextPrimary)
                    if let subtitle = self.spot.subtitle {
                        TabiLabel(title: subtitle, style: .captionM, color: .tabiTextSecondary)
                    }
                    TabiLabel(title: self.spot.durationTitle, style: .captionM, color: .tabiTextTertiary)
                }
                .padding(12)
            }
        }
    }
}

// MARK: - View

private extension PlanDetailSpotRow {
    var timeline: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TabiColor.tabiBorder)
                .opacity(self.isFirst ? 0 : 1)
                .frame(width: 2)

            Circle()
                .fill(self.spot.category.color)
                .frame(width: 10, height: 10)

            Rectangle()
                .fill(TabiColor.tabiBorder)
                .opacity(self.isLast ? 0 : 1)
                .frame(width: 2)
        }
        .frame(width: 10)
    }
}
