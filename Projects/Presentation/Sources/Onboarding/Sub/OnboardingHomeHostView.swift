//
//  OnboardingHomeHostView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

/// 온보딩 홈 스텝에서 실제 `HomeFeature`/`HomeView`를 그대로 렌더링한다. 위치·환율·주변 관광지·축제·
/// 여행 일정 UseCase를 Test 더블 + `OnboardingMock` 데이터로 오버라이드해, 실제 네트워크·위치·DB 호출
/// 없이 화면을 채운다. 카테고리 칩 탭(`HomeFeature.Action.categoryTapped`)만 가로채 온보딩 진행 신호로 전달한다
struct OnboardingHomeHostView: View {

    @State private var store: StoreOf<HomeFeature>
    @Namespace private var namespace

    init(onCategoryTapped: @escaping (CategoryType) -> Void) {
        self._store = State(initialValue: Store(
            initialState: Self.makeInitialState(),
            reducer: { OnboardingHomeProgressReducer(onCategoryTapped: onCategoryTapped) },
            withDependencies: { dependency in
                let locationUseCase = TestLocationUseCase()
                locationUseCase.coordinate = .seoulCityHall
                locationUseCase.region = .korea(.seoul)
                dependency.locationUseCase = locationUseCase

                dependency.exchangeRateUseCase = TestExchangeRateUseCase()

                let touristSpotUseCase = TestTouristSpotUseCase()
                touristSpotUseCase.nearbySpots = OnboardingMock.nearbySpots
                dependency.touristSpotUseCase = touristSpotUseCase

                dependency.festivalUseCase = TestFestivalUseCase()

                let travelPlanUseCase = TestTravelPlanUseCase()
                travelPlanUseCase.plans = OnboardingMock.plans
                dependency.travelPlanUseCase = travelPlanUseCase

                dependency.analyticsCenter = TestAnalyticsCenter()
            }
        ))
    }

    var body: some View {
        HomeView(store: self.store, namespace: self.namespace)
    }
}

// MARK: - Method

private extension OnboardingHomeHostView {
    /// 위치 권한·지역·주변 정보를 이미 로드된 최종 값으로 미리 채워, `onAppear`의 1초 지연 위치 조회
    /// 이펙트를 기다리는 동안 로딩 스켈레톤/빈 상태가 잠깐 노출되는 것을 방지한다(더미 데이터이므로
    /// 뒤늦게 도착하는 이펙트 결과도 동일 값이라 화면 변화가 없다)
    static func makeInitialState() -> HomeFeature.State {
        var state = HomeFeature.State()
        state.locationStatus = .allowed
        state.currentRegion = .korea(.seoul)
        state.hasLoadedInitialSpots = true
        state.nearbyTouristSpots = OnboardingMock.nearbySpots
        state.nearbyRestaurants = OnboardingMock.nearbySpots
        state.isLoadingTouristSpots = false
        state.isLoadingRestaurants = false
        return state
    }
}

// MARK: - OnboardingHomeProgressReducer

/// `HomeFeature`를 그대로 조립하되, `categoryTapped` 액션만 옆에서 관찰해 온보딩 진행 콜백을 호출하는
/// 얇은 래퍼 Reducer. `HomeFeature`의 State/Action/로직은 전혀 변형하지 않는다
private struct OnboardingHomeProgressReducer: Reducer {
    let onCategoryTapped: (CategoryType) -> Void

    var body: some ReducerOf<HomeFeature> {
        HomeFeature()
        Reduce { _, action in
            if case .categoryTapped(let category) = action {
                self.onCategoryTapped(category)
            }
            return .none
        }
    }
}
