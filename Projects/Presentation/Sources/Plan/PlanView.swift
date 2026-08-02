//
//  PlanView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct PlanView: View {

    @Bindable private var store: StoreOf<PlanFeature>

    public init(store: StoreOf<PlanFeature>) {
        self.store = store
    }

    public var body: some View {
        self.planList()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.Plan.title) {
                    self.newPlanButton()
                }
            }
            .sheet(item: self.$store.scope(state: \.addPlanState, action: \.addPlan)) { store in
                AddTravelPlanView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension PlanView {
    func newPlanButton() -> some View {
        Button {
            self.store.send(.addButtonTapped)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                TabiLabel(title: Strings.Plan.newPlanButton, style: .bodyMBold, color: .tabiOnColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(TabiColor.tabiPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(TabiPressStyle())
    }

    func planList() -> some View {
        GeometryReader { proxy in
            List {
                if self.store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: proxy.size.height)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                } else if self.store.plans.isEmpty {
                    PlanEmptyState()
                        .frame(height: proxy.size.height)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                } else {
                    self.section(.ongoing, plans: self.store.ongoingPlans)
                    self.section(.upcoming, plans: self.store.upcomingPlans)
                    self.section(.past, plans: self.store.pastPlans)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    func section(_ section: PlanSection, plans: [TravelPlan]) -> some View {
        if !plans.isEmpty {
            Section {
                ForEach(plans) { plan in
                    PlanCardView(
                        plan: plan,
                        onTapped: { self.store.send(.planTapped(id: plan.id)) },
                        onDayChipTapped: { dayIndex in self.store.send(.dayChipTapped(id: plan.id, dayIndex: dayIndex)) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden)
                }
            } header: {
                TabiLabel(title: section.title, style: .bodyMBold, color: .tabiTextPrimary)
            }
        }
    }
}
