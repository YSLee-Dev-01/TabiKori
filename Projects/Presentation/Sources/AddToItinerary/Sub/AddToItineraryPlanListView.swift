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
    let isFetchingDetail: Bool
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
                    LazyVStack(alignment: .leading, spacing: 20) {
                        self.planGroup(.ongoing, plans: self.ongoingPlans)
                        self.planGroup(.upcoming, plans: self.upcomingPlans)
                        self.planGroup(.past, plans: self.pastPlans)
                    }
                    .padding(20)
                }
                .disabled(self.isFetchingDetail)
                .overlay {
                    if self.isFetchingDetail {
                        ProgressView()
                    }
                }
            }
        }
    }
}

// MARK: - Method

private extension AddToItineraryPlanListView {
    var ongoingPlans: [TravelPlan] { self.plans.filter { $0.section == .ongoing } }
    var upcomingPlans: [TravelPlan] { self.plans.filter { $0.section == .upcoming } }
    var pastPlans: [TravelPlan] { self.plans.filter { $0.section == .past } }

    @ViewBuilder
    func planGroup(_ section: PlanSection, plans: [TravelPlan]) -> some View {
        if !plans.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                TabiLabel(title: section.title, style: .bodyMBold, color: .tabiTextPrimary)
                VStack(spacing: 12) {
                    ForEach(plans) { plan in
                        self.planSection(plan)
                    }
                }
            }
        }
    }

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
            }
        }
        .animation(.tabiFast, value: isExpanded)
    }
}
