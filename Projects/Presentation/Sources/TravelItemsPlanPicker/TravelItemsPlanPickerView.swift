//
//  TravelItemsPlanPickerView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

struct TravelItemsPlanPickerView: View {

    @Bindable private var store: StoreOf<TravelItemsPlanPickerFeature>

    init(store: StoreOf<TravelItemsPlanPickerFeature>) {
        self.store = store
    }

    var body: some View {
        self.content()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.TravelItems.planPickerTitle) {
                    self.closeButton()
                }
                .padding(.top, 26)
                .padding(.bottom, 16)
            }
            .disabled(self.store.isSaving)
            .overlay {
                if self.store.isSaving {
                    ProgressView()
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension TravelItemsPlanPickerView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeButtonTapped)
        }
    }

    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.plans.isEmpty {
            TabiEmptyState(
                systemImageName: "calendar",
                title: Strings.TravelItems.planPickerEmptyTitle,
                description: Strings.TravelItems.planPickerEmptyDescription
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    self.planGroup(.ongoing, plans: self.plans(in: .ongoing))
                    self.planGroup(.upcoming, plans: self.plans(in: .upcoming))
                    self.planGroup(.past, plans: self.plans(in: .past))
                }
                .padding(20)
            }
        }
    }

    func plans(in section: PlanSection) -> [TravelPlan] {
        self.store.plans.filter { $0.section == section }
    }

    @ViewBuilder
    func planGroup(_ section: PlanSection, plans: [TravelPlan]) -> some View {
        if plans.isEmpty == false {
            VStack(alignment: .leading, spacing: 12) {
                TabiLabel(title: section.title, style: .bodyMBold, color: .tabiTextPrimary)
                VStack(spacing: 12) {
                    ForEach(plans) { plan in
                        TravelItemsPlanPickerRow(plan: plan) {
                            self.store.send(.planRowTapped(plan))
                        }
                    }
                }
            }
        }
    }
}
