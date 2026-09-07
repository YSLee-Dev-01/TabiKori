//
//  OnboardingMapHostView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

/// 온보딩 지도 스텝에서 실제 `MapFeature`/`MapView` 구조(검색 결과 카드 등)를 그대로 렌더링하되,
/// 지도 SDK(TabiMapView) 배경만 `OnboardingMapBackgroundMockView`로 대체해 실제 지도 타일 네트워크
/// 호출을 피한다. 검색 결과는 초기 상태에 `OnboardingMock.searchResults`를 직접 채워 실제 검색 없이
/// 바로 노출하고, 첫 번째 검색 결과 카드 탭(`MapFeature.Action.searchResultTapped`)만 가로채
/// 온보딩 진행 신호로 전달한다
struct OnboardingMapHostView: View {

    @State private var store: StoreOf<MapFeature>

    init(onSearchResultTapped: @escaping () -> Void) {
        self._store = State(initialValue: Store(
            initialState: Self.makeInitialState(),
            reducer: { OnboardingMapProgressReducer(onSearchResultTapped: onSearchResultTapped) },
            withDependencies: { dependency in
                dependency.locationUseCase = TestLocationUseCase()
                dependency.touristSpotUseCase = TestTouristSpotUseCase()
                dependency.subwayStationUseCase = TestSubwayStationUseCase()
                dependency.searchHistoryUseCase = TestSearchHistoryUseCase()
                dependency.autoTranslateSearchUseCase = TestAutoTranslateSearchUseCase()
                dependency.analyticsCenter = TestAnalyticsCenter()
            }
        ))
    }

    var body: some View {
        MapView(store: self.store, mapBackgroundOverride: AnyView(OnboardingMapBackgroundMockView()))
    }
}

// MARK: - Method

private extension OnboardingMapHostView {
    /// 검색 결과 카드가 별도 탭 없이 바로 보이도록, 초기 State를 결과 화면(mode: .result) 상태로 채운다.
    /// `MapFeature.State`의 검색 관련 필드는 내부(internal) 접근이라 같은(Presentation) 모듈에서 직접 설정 가능하다.
    /// `MapView`는 `searchQuery`가 비어있고 카테고리 검색도 아니면 결과 리스트 대신 검색 안내 화면을 그리므로
    /// (`activeCategory`는 `fileprivate`라 외부에서 설정 불가), `searchQuery`를 첫 번째 더미 결과와 어울리는
    /// 값으로 채워 결과 리스트가 곧바로 노출되게 한다
    static func makeInitialState() -> MapFeature.State {
        var state = MapFeature.State()
        state.mode = .result
        state.panelStage = .half
        state.searchQuery = "북촌한옥마을"
        state.searchResults = OnboardingMock.searchResults
        return state
    }
}

// MARK: - OnboardingMapProgressReducer

/// `MapFeature`를 그대로 조립하되, `searchResultTapped` 액션만 옆에서 관찰해 온보딩 진행 콜백을 호출하는
/// 얇은 래퍼 Reducer. `MapFeature`의 State/Action/로직은 전혀 변형하지 않는다
private struct OnboardingMapProgressReducer: Reducer {
    let onSearchResultTapped: () -> Void

    var body: some ReducerOf<MapFeature> {
        MapFeature()
        Reduce { _, action in
            if case .searchResultTapped = action {
                self.onSearchResultTapped()
            }
            return .none
        }
    }
}
