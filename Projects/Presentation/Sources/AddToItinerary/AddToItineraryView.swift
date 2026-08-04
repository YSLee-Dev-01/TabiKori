//
//  AddToItineraryView.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// 관광지 상세 하단 sheet. Step 1(일정/날짜 선택)과 Step 2(시작·종료 시각 입력)를 전환하며 보여준다
struct AddToItineraryView: View {
    @Bindable private var store: StoreOf<AddToItineraryFeature>

    init(store: StoreOf<AddToItineraryFeature>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            self.header()
            Group {
                switch self.store.step {
                case .selectingPlan:
                    AddToItineraryPlanListView(
                        plans: self.store.plans,
                        isLoading: self.store.isLoading,
                        expandedPlanId: self.store.expandedPlanId,
                        onPlanTapped: { self.store.send(.planRowTapped($0)) },
                        onDayTapped: { plan, dayIndex, date in
                            self.store.send(.dayRowTapped(plan: plan, dayIndex: dayIndex, date: date))
                        }
                    )
                    .transition(.move(edge: .leading))

                case .configuringTime:
                    AddToItineraryTimeConfigView(
                        planTitle: self.store.selectedPlan?.title ?? "",
                        dayTitle: Strings.Plan.dayChipTitle(self.store.selectedDayIndex + 1),
                        dateTitle: self.store.selectedDate.planDayHeaderTitle,
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
            .animation(.tabiStandard, value: self.store.step)
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - Method

private extension AddToItineraryView {
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
            TabiLabel(title: Strings.Detail.ctaAddToItinerary, style: .titleS, color: .tabiTextPrimary)
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
}

#Preview {
    let mockTravelPlanUseCase: TestTravelPlanUseCase = {
        let useCase = TestTravelPlanUseCase()
        useCase.plans = [.mock]
        return useCase
    }()
    let mockDetailUseCase: TestTravelPlanDetailUseCase = {
        let useCase = TestTravelPlanDetailUseCase()
        useCase.details = [.mock]
        return useCase
    }()

    AddToItineraryView(
        store: Store(
            initialState: AddToItineraryFeature.State(
                touristSpot: TouristSpot(
                    id: "264337",
                    title: "景福宮（경복궁）",
                    thumbnailURLString: nil,
                    distanceMeters: 1200,
                    contentType: .sightseeing,
                    coordinate: Coordinate(latitude: 37.5788, longitude: 126.9770)
                ),
                address: "ソウル特別市鍾路区社稷路161"
            ),
            reducer: { AddToItineraryFeature() },
            withDependencies: { dependency in
                dependency.travelPlanUseCase = mockTravelPlanUseCase
                dependency.travelPlanDetailUseCase = mockDetailUseCase
            }
        )
    )
}
