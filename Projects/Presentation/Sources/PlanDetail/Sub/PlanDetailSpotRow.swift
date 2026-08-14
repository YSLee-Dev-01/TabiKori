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
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let isEditing: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TabiLabel(title: self.spot.startTimeTitle, style: .captionMBold, color: .tabiTextSecondary)
                .frame(width: 40, alignment: .leading)
                .padding(.top, 4)

            self.timeline

            TabiCard {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        TabiTag(self.spot.category.label, color: self.spot.category.color)
                        TabiLabel(title: self.spot.title, style: .bodyMBold, color: .tabiTextPrimary)
                        if let subtitle = self.spot.subtitle {
                            TabiLabel(title: subtitle, style: .captionM, color: .tabiTextSecondary)
                        }
                        TabiLabel(title: self.spot.durationTitle, style: .captionM, color: .tabiTextTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if self.isEditing == false {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
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
                .overlay {
                    TabiLabel(title: "\(self.index)", style: .captionXSBold, color: .tabiOnColor)
                }
                .frame(width: 22, height: 22)

            Rectangle()
                .fill(TabiColor.tabiBorder)
                .opacity(self.isLast ? 0 : 1)
                .frame(width: 2)
        }
        .frame(width: 22)
    }
}
