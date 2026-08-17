//
//  PlanTravelItemsView.swift
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

/// 플랜에 저장된 준비물 체크리스트 화면. PlanDetail 일자 헤더의 "준비물" 버튼에서 push된다
public struct PlanTravelItemsView: View {

    @Bindable private var store: StoreOf<PlanTravelItemsFeature>

    public init(store: StoreOf<PlanTravelItemsFeature>) {
        self.store = store
    }

    public var body: some View {
        self.content()
            .navigationTitle(Strings.TravelItems.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension PlanTravelItemsView {
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.items.isEmpty {
            TabiEmptyState(
                systemImageName: "shippingbox",
                title: Strings.TravelItems.savedEmptyTitle,
                description: Strings.TravelItems.savedEmptyDescription
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    ForEach(self.store.items) { item in
                        PlanTravelItemCheckRow(item: item) {
                            self.store.send(.itemTapped(id: item.id))
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                } header: {
                    TabiLabel(
                        title: Strings.TravelItems.checkedCountTitle(self.store.checkedCount, self.store.items.count),
                        style: .captionMBold,
                        color: .tabiTextSecondary
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    let mockUseCase: TestTravelItemUseCase = {
        let useCase = TestTravelItemUseCase()
        useCase.savedItems = [
            TravelPlanItem(id: UUID(), planId: TravelPlan.mock.id, order: 0, title: "パスポート", note: "有効期限を確認", isChecked: true),
            TravelPlanItem(id: UUID(), planId: TravelPlan.mock.id, order: 1, title: "充電器", note: nil, isChecked: false)
        ]
        return useCase
    }()

    NavigationStack {
        PlanTravelItemsView(
            store: Store(
                initialState: PlanTravelItemsFeature.State(plan: .mock),
                reducer: { PlanTravelItemsFeature() },
                withDependencies: { dependency in
                    dependency.travelItemUseCase = mockUseCase
                }
            )
        )
    }
}
