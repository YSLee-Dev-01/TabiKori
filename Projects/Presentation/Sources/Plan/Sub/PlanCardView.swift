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

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(self.plan.dayChipTitles.enumerated()), id: \.offset) { _, title in
                        self.dayChip(title)
                    }
                }
            }
            .scrollIndicators(.hidden)

            HStack {
                TabiLabel(title: Strings.Plan.totalSpotCountFixed, style: .captionM, color: .tabiTextTertiary)
                Spacer()
                TabiLabel(title: Strings.Plan.tapToViewDetail, style: .captionM, color: .tabiTextTertiary)
            }
        }
        .padding(16)
    }

    /// 표시 전용 일자 칩. `TabiChip`은 `action` 클로저가 필수인 Button 기반 컴포넌트라
    /// 카드 전체를 감싸는 Button 내부에 중첩하면 탭 제스처가 씹히므로, 탭 대상이 아닌 이 칩은 Button 없이 구현한다
    func dayChip(_ title: String) -> some View {
        TabiLabel(title: title, style: .captionM, color: .tabiTextSecondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
    }
}
