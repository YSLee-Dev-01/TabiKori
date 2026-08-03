//
//  PlanDetailView.swift
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

/// 일정 상세 화면. NavigationBar와 일자 선택 탭, 선택된 날짜의 스팟 목록(타임라인 + 스와이프 삭제)을 표시한다
public struct PlanDetailView: View {

    private let store: StoreOf<PlanDetailFeature>

    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.navigationBar(plan: self.store.plan)
            self.dayTabScroll(plan: self.store.plan)
            if let dateTitle = self.selectedDayDateTitle(plan: self.store.plan) {
                PlanDetailDayHeader(
                    dateTitle: dateTitle,
                    spotCountTitle: self.spotCountTitle
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            // TODO: 지도 영역 추가
            EmptyView()
            self.spotList()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactivePopGestureEnabled(true)
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension PlanDetailView {
    func navigationBar(plan: TravelPlan) -> some View {
        TabiNavigationBar(
            subtitle: "\(plan.displayRegionTitle) · \(Strings.Plan.durationBadge(plan.dayCount))",
            title: plan.title
        )
        .padding(.top, 20)
    }

    func dayTabScroll(plan: TravelPlan) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(plan.dayDates.enumerated()), id: \.offset) { offset, date in
                    PlanDetailDayButton(
                        dayTitle: Strings.Plan.dayChipTitle(offset + 1),
                        dateTitle: date.planDayDateTitle,
                        isSelected: self.store.selectedDayIndex == offset
                    ) {
                        self.store.send(.dayButtonTapped(index: offset))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 20)
    }

    func selectedDayDateTitle(plan: TravelPlan) -> String? {
        guard plan.dayDates.indices.contains(self.store.selectedDayIndex) else { return nil }
        return plan.dayDates[self.store.selectedDayIndex].planDayHeaderTitle
    }

    var spotCountTitle: String {
        let count = self.store.selectedDaySpots.count
        return count == 0 ? Strings.Plan.spotCountZero : Strings.Plan.spotCountTitle(count)
    }

    func spotList() -> some View {
        List {
            if self.store.selectedDaySpots.isEmpty {
                PlanDetailSpotEmptyState()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            } else {
                let spots = self.store.selectedDaySpots
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    PlanDetailSpotRow(
                        spot: spot,
                        isFirst: index == 0,
                        isLast: index == spots.count - 1
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            self.store.send(.spotDeleteButtonTapped(id: spot.id))
                        } label: {
                            Text(Strings.Common.delete)
                        }
                    }
                }
            }

            PlanDetailAddSpotButton {
                self.store.send(.addSpotButtonTapped)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    let mockDetailUseCase: TestTravelPlanDetailUseCase = {
        let useCase = TestTravelPlanDetailUseCase()
        useCase.details = [.mock]
        return useCase
    }()

    NavigationStack {
        PlanDetailView(
            store: Store(
                initialState: PlanDetailFeature.State(plan: .mock),
                reducer: { PlanDetailFeature() },
                withDependencies: { dependency in
                    dependency.travelPlanDetailUseCase = mockDetailUseCase
                }
            )
        )
    }
}
