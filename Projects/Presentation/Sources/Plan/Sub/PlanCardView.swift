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
    let onDayChipTapped: (Int) -> Void

    @State private var isPressed = false

    var body: some View {
        TabiCard {
            VStack(spacing: 0) {
                self.banner()
                self.content()
            }
        }
        .scaleEffect(self.isPressed ? 0.92 : 1)
        .geometryGroup()
        .animation(
            self.isPressed ? .none : .spring(response: 0.4, dampingFraction: 0.6),
            value: self.isPressed
        )
        .contentShape(Rectangle())
        .onTapGesture {
            self.onTapped()
        }
        .simultaneousGesture(self.pressStateGesture())
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
                    ForEach(Array(self.plan.dayChipTitles.enumerated()), id: \.offset) { offset, title in
                        self.dayChip(title, dayIndex: offset)
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

    /// 실제 탭 가능한 일자 칩. 카드 전체는 Button이 아닌 `onTapGesture` 기반 탭 처리로 바뀌었으므로,
    /// 이 칩은 독립된 `Button`으로 두어도 카드 전체 탭 제스처와 서로의 액션을 침범하지 않는다
    func dayChip(_ title: String, dayIndex: Int) -> some View {
        Button {
            self.onDayChipTapped(dayIndex)
        } label: {
            TabiLabel(title: title, style: .captionM, color: .tabiTextSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(TabiColor.tabiSurface)
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(TabiColor.tabiBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Method

private extension PlanCardView {
    /// `TabiPressStyle`과 동일한 프레스 피드백(스케일 0.92, 스프링 애니메이션)을 카드 전체 탭 영역에 적용하기 위한 제스처.
    /// 카드가 더 이상 `Button`이 아니므로 `ButtonStyle`을 직접 쓸 수 없어 `DragGesture`로 눌림 상태를 추적한다
    func pressStateGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in self.isPressed = true }
            .onEnded { _ in self.isPressed = false }
    }
}
