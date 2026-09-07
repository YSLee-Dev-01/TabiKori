//
//  OnboardingPlanDetailHostView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

/// 온보딩 일정상세 스텝에서 실제 `PlanDetailFeature`/`PlanDetailView`를 그대로 렌더링한다
/// (`PlanDetailView`의 `#Preview`가 이미 쓰는, `TestTravelPlanDetailUseCase`를 `withDependencies`로
/// 주입해 실제 뷰를 그리는 패턴을 그대로 재사용).
///
/// `PlanDetailFeature.onAppear`는 상세 조회 이후 공유 파일(JSON) 생성 이펙트(`updateShareFileURLEffect`)를
/// 자동으로 함께 실행하므로, 그 경로에서 참조되는 자동 오늘 스크롤 설정·쇼핑/준비물 리스트·일정 공유
/// UseCase도 함께 Test 더블로 오버라이드해 실제 DB 호출이 섞이지 않게 한다.
/// 둘째 날(index 1) Day 칩 탭(`PlanDetailFeature.Action.dayButtonTapped`)과 지도 전체보기 버튼 탭
/// (`PlanDetailFeature.Action.fullMapButtonTapped`)만 가로채 온보딩 진행 신호로 전달한다
struct OnboardingPlanDetailHostView: View {

    @State private var store: StoreOf<PlanDetailFeature>

    init(onDayTapped: @escaping (Int) -> Void, onFullMapTapped: @escaping () -> Void) {
        self._store = State(initialValue: Store(
            initialState: PlanDetailFeature.State(plan: OnboardingMock.plan),
            reducer: { OnboardingPlanDetailProgressReducer(onDayTapped: onDayTapped, onFullMapTapped: onFullMapTapped) },
            withDependencies: { dependency in
                let travelPlanDetailUseCase = TestTravelPlanDetailUseCase()
                travelPlanDetailUseCase.details = [OnboardingMock.planDetail]
                dependency.travelPlanDetailUseCase = travelPlanDetailUseCase

                dependency.autoScrollToTodayUseCase = TestAutoScrollToTodayUseCase()
                dependency.shoppingPlanItemUseCase = TestShoppingPlanItemUseCase()
                dependency.toolBarItemUseCase = TestToolBarItemUseCase()
                dependency.travelPlanShareUseCase = TestTravelPlanShareUseCase()
            }
        ))
    }

    var body: some View {
        // 날짜 헤더 자동 숨김(스크롤 기반)을 비활성화해, 이 스텝에서 날짜 헤더가 항상 보이도록 강제한다
        // (PlanDetailView.isDayHeaderAutoHideDisabled 문서 참고)
        PlanDetailView(store: self.store, isDayHeaderAutoHideDisabled: true)
    }
}

// MARK: - OnboardingPlanDetailProgressReducer

/// `PlanDetailFeature`를 그대로 조립하되, `dayButtonTapped`/`fullMapButtonTapped` 액션만 옆에서 관찰해
/// 온보딩 진행 콜백을 호출하는 얇은 래퍼 Reducer. `PlanDetailFeature`의 State/Action/로직은 전혀 변형하지 않는다.
/// `fullMapButtonTapped`는 프로덕션에서도 `PlanDetailFeature` 자체는 `.none`만 반환하고 상위(TabBarFeature)가
/// 가로채 지도 전체화면으로 push하는 액션이라(NavigationStack이 없는 온보딩에서는 그 push가 일어나지 않으므로),
/// `PlanDetailFeature()`에 그대로 위임해도 동작에 영향이 없다
private struct OnboardingPlanDetailProgressReducer: Reducer {
    let onDayTapped: (Int) -> Void
    let onFullMapTapped: () -> Void

    var body: some ReducerOf<PlanDetailFeature> {
        PlanDetailFeature()
        Reduce { _, action in
            switch action {
            case .dayButtonTapped(let index):
                self.onDayTapped(index)

            case .fullMapButtonTapped:
                self.onFullMapTapped()

            default:
                break
            }
            return .none
        }
    }
}
