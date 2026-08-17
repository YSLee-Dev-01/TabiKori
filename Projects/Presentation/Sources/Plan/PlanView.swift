//
//  PlanView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

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
                    self.planMenuButton()
                }
            }
            .sheet(item: self.$store.scope(state: \.addPlanState, action: \.addPlan)) { store in
                AddTravelPlanView(store: store)
            }
            .fileImporter(
                isPresented: Binding(
                    get: { self.store.isImporterPresented },
                    set: { self.store.send(.importerPresentationChanged($0)) }
                ),
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    self.store.send(.importFileSelected(url))
                case .failure:
                    self.store.send(.importFileSelected(nil))
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension PlanView {
    func planMenuButton() -> some View {
        Menu {
            Button(Strings.Plan.addMenuTitle) {
                self.store.send(.addButtonTapped)
            }
            Button(Strings.Plan.importMenuTitle) {
                self.store.send(.importButtonTapped)
            }
        } label: {
            TabiGlassIconLabel(systemName: "ellipsis", size: .ml, foregroundColor: .tabiPrimary)
        }
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
                        spotCount: self.store.spotCounts[plan.id] ?? 0,
                        onTapped: { self.store.send(.planTapped(plan: plan)) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            self.store.send(.planDeleteButtonTapped(id: plan.id))
                        } label: {
                            Text(Strings.Common.delete)
                        }
                    }
                }
            } header: {
                TabiLabel(title: section.title, style: .bodyMBold, color: .tabiTextPrimary)
            }
        }
    }
}
