//
//  PlanDetailAddSpotView.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// PlanDetail "+" 버튼으로 여는 하단 시트. Step 1(스팟 선택)과 Step 2(시각 설정)를 전환하며 보여준다
struct PlanDetailAddSpotView: View {
    @Bindable private var store: StoreOf<PlanDetailAddSpotFeature>

    init(store: StoreOf<PlanDetailAddSpotFeature>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            self.header()
            self.stepContent()
                .animation(.tabiStandard, value: self.store.step)
        }
    }
}

// MARK: - View

private extension PlanDetailAddSpotView {
    func header() -> some View {
        HStack(spacing: 12) {
            if self.store.step == .configuringTime {
                Button {
                    self.store.send(.backButtonTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(TabiColor.tabiTextPrimary)
                }
            }
            TabiLabel(title: Strings.Plan.spotAddButtonTitle, style: .titleS, color: .tabiTextPrimary)
            Spacer()
            Button {
                self.store.send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(TabiColor.tabiTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    func stepContent() -> some View {
        switch self.store.step {
        case .selectingSpot:
            self.selectingSpotView()
                .transition(.move(edge: .leading))

        case .configuringTime:
            AddToItineraryTimeConfigView(
                planTitle: self.store.selectedSpot?.japaneseTitle ?? "",
                dayTitle: Strings.Plan.dayChipTitle(self.store.dayIndex + 1),
                dateTitle: self.store.date.planDayHeaderTitle,
                startTime: self.$store.startTime,
                endTime: self.$store.endTime,
                durationMinutes: self.store.durationMinutes,
                isSaveEnabled: self.store.isSaveEnabled,
                isSaving: self.store.isSaving,
                onSaveTapped: { self.store.send(.saveButtonTapped) }
            )
            .transition(.move(edge: .trailing))
        }
    }

    func selectingSpotView() -> some View {
        VStack(spacing: 16) {
            PlanDetailAddSpotTabBar(selectedTab: self.store.tab) { tab in
                self.store.send(.tabSelected(tab))
            }
            .padding(.horizontal, 20)

            switch self.store.tab {
            case .search:
                PlanDetailAddSpotSearchListView(
                    keyword: self.$store.searchKeyword,
                    results: self.store.searchResults,
                    isLoading: self.store.isSearchLoading,
                    hasSearched: self.store.hasSearched,
                    onSubmit: { self.store.send(.searchSubmitted) },
                    onSpotTapped: { self.store.send(.spotRowTapped($0)) }
                )
                .padding(.horizontal, 20)

            case .bookmark:
                PlanDetailAddSpotBookmarkListView(
                    bookmarks: self.store.bookmarks,
                    isLoading: self.store.isBookmarkLoading,
                    onSpotTapped: { self.store.send(.spotRowTapped($0)) }
                )
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    let mockTouristSpotUseCase: TestTouristSpotUseCase = {
        let useCase = TestTouristSpotUseCase()
        useCase.searchResults = []
        return useCase
    }()
    let mockBookmarkUseCase: TestBookmarkUseCase = {
        let useCase = TestBookmarkUseCase()
        useCase.bookmarks = []
        return useCase
    }()
    let mockDetailUseCase: TestTravelPlanDetailUseCase = {
        let useCase = TestTravelPlanDetailUseCase()
        useCase.details = [.mock]
        return useCase
    }()

    PlanDetailAddSpotView(
        store: Store(
            initialState: PlanDetailAddSpotFeature.State(
                planId: TravelPlan.mock.id,
                dayIndex: 0,
                date: Date(),
                detail: .mock
            ),
            reducer: { PlanDetailAddSpotFeature() },
            withDependencies: { dependency in
                dependency.touristSpotUseCase = mockTouristSpotUseCase
                dependency.bookmarkUseCase = mockBookmarkUseCase
                dependency.travelPlanDetailUseCase = mockDetailUseCase
            }
        )
    )
}
