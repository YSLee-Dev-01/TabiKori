//
//  OnboardingPlanDetailStepView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct OnboardingPlanDetailStepView: View {
    let selectedDayIndex: Int
    let onDayTapped: (Int) -> Void

    private var daySpots: [TravelPlanDetailSpot] {
        OnboardingMock.planDetail.spots
            .filter { $0.dayIndex == self.selectedDayIndex }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        OnboardingStepFrame(
            title: OnboardingStep.planDetail.title,
            description: OnboardingStep.planDetail.description
        ) {
            VStack(alignment: .leading, spacing: 16) {
                self.dayChipRow()

                PlanDetailDayHeader(
                    dateTitle: OnboardingMock.plan.dayDates[self.selectedDayIndex].planDayHeaderTitle,
                    spotCountTitle: nil
                )

                self.timeline()
            }
        }
    }
}

// MARK: - View

private extension OnboardingPlanDetailStepView {
    func dayChipRow() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(OnboardingMock.plan.dayDates.indices, id: \.self) { dayIndex in
                    TabiChip(
                        Strings.Plan.dayChipTitle(dayIndex + 1),
                        isSelected: dayIndex == self.selectedDayIndex
                    ) {
                        self.onDayTapped(dayIndex)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    func timeline() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(self.daySpots.enumerated()), id: \.element.id) { index, spot in
                PlanDetailSpotRow(
                    spot: spot,
                    index: index + 1,
                    isFirst: index == 0,
                    isLast: index == self.daySpots.count - 1,
                    isEditing: false
                )
            }
        }
    }
}
