//
//  AddToItineraryPlanListView.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

/// Step 1 — 일정 목록. 각 일정을 탭하면 아코디언으로 펼쳐져 날짜 목록이 표시된다
struct AddToItineraryPlanListView: View {
    let plans: [TravelPlan]
    let isLoading: Bool
    let expandedPlanId: UUID?
    let onPlanTapped: (TravelPlan) -> Void
    let onDayTapped: (TravelPlan, Int, Date) -> Void

    var body: some View {
        Group {
            if self.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if self.plans.isEmpty {
                AddToItineraryEmptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(self.plans) { plan in
                            self.planSection(plan)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Method

private extension AddToItineraryPlanListView {
    @ViewBuilder
    func planSection(_ plan: TravelPlan) -> some View {
        let isExpanded = self.expandedPlanId == plan.id
        VStack(spacing: 8) {
            AddToItineraryPlanRow(plan: plan, isExpanded: isExpanded) {
                self.onPlanTapped(plan)
            }
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(plan.dayDates.enumerated()), id: \.offset) { offset, date in
                        AddToItineraryDayRow(
                            dayTitle: Strings.Plan.dayChipTitle(offset + 1),
                            dateTitle: date.planDayHeaderTitle
                        ) {
                            self.onDayTapped(plan, offset, date)
                        }
                    }
                }
                .padding(.leading, 12)
            }
        }
        .animation(.tabiFast, value: isExpanded)
    }
}
