//
//  AddToItineraryPlanRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

/// 일정 한 건을 나타내는 아코디언 헤더 행
struct AddToItineraryPlanRow: View {
    let plan: TravelPlan
    let isExpanded: Bool
    let onTapped: () -> Void

    var body: some View {
        Button {
            self.onTapped()
        } label: {
            TabiCard {
                HStack(spacing: 12) {
                    Text(self.plan.displayEmoji)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        TabiLabel(title: self.plan.title, style: .bodyMBold, color: .tabiTextPrimary)
                        TabiLabel(
                            title: "\(self.plan.displayRegionTitle) · \(self.plan.periodTitle)",
                            style: .captionM,
                            color: .tabiTextSecondary
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                        .rotationEffect(.degrees(self.isExpanded ? 180 : 0))
                }
                .padding(16)
            }
        }
        .buttonStyle(TabiPressStyle())
        .animation(.tabiFast, value: self.isExpanded)
    }
}
