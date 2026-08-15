//
//  PlanCardView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanCardView: View {
    let plan: TravelPlan
    let spotCount: Int
    let onTapped: () -> Void

    var body: some View {
        Button {
            self.onTapped()
        } label: {
            TabiCard {
                VStack(spacing: 0) {
                    self.banner()
                    self.content()
                }
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}

// MARK: - View

private extension PlanCardView {
    func banner() -> some View {
        HStack {
            Text(self.plan.displayEmoji)
                .font(.system(size: 32))

            Spacer()

            TabiLabel(
                title: Strings.Plan.durationBadge(self.plan.dayCount),
                style: .captionMBold,
                color: .tabiOnColor
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(TabiColor.tabiPrimary)
    }

    func content() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TabiLabel(title: self.plan.title, style: .titleS, color: .tabiTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(TabiColor.tabiTextTertiary)
            }

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(TabiColor.tabiTextSecondary)
                TabiLabel(
                    title: "\(self.plan.displayRegionTitle) · \(self.plan.periodTitle)",
                    style: .captionM,
                    color: .tabiTextSecondary
                )
            }

            TabiLabel(title: Strings.Plan.totalSpotCount(self.spotCount), style: .captionM, color: .tabiTextTertiary)
        }
        .padding(16)
    }
}
