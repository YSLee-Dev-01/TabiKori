//
//  OnboardingPlanHostView.swift
//  Presentation
//
//  Created by Claude on 8/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

/// 온보딩 일정 스텝에서 실제 `PlanFeature`/`PlanView`를 그대로 렌더링한다. 여행 일정·일정상세 UseCase와
/// 위젯 스냅샷 저장소를 Test 더블 + `OnboardingMock` 데이터로 오버라이드해, 실제 DB(App Group 위젯 스냅샷
/// 포함) 호출 없이 화면을 채운다. 첫 번째 일정 카드 탭(`PlanFeature.Action.planTapped`)만 가로채
/// 온보딩 진행 신호로 전달한다
struct OnboardingPlanHostView: View {

    @State private var store: StoreOf<PlanFeature>

    init(onPlanTapped: @escaping () -> Void) {
        self._store = State(initialValue: Store(
            initialState: PlanFeature.State(),
            reducer: { OnboardingPlanProgressReducer(onPlanTapped: onPlanTapped) },
            withDependencies: { dependency in
                let travelPlanUseCase = TestTravelPlanUseCase()
                travelPlanUseCase.plans = OnboardingMock.plans
                dependency.travelPlanUseCase = travelPlanUseCase

                let travelPlanDetailUseCase = TestTravelPlanDetailUseCase()
                travelPlanDetailUseCase.details = [OnboardingMock.planDetail]
                dependency.travelPlanDetailUseCase = travelPlanDetailUseCase

                dependency.widgetSnapshotStore = TestWidgetSnapshotStore()
            }
        ))
    }

    var body: some View {
        PlanView(store: self.store)
    }
}

// MARK: - OnboardingPlanProgressReducer

/// `PlanFeature`를 그대로 조립하되, `planTapped` 액션만 옆에서 관찰해 온보딩 진행 콜백을 호출하는
/// 얇은 래퍼 Reducer. `PlanFeature`의 State/Action/로직은 전혀 변형하지 않는다
private struct OnboardingPlanProgressReducer: Reducer {
    let onPlanTapped: () -> Void

    var body: some ReducerOf<PlanFeature> {
        PlanFeature()
        Reduce { _, action in
            if case .planTapped = action {
                self.onPlanTapped()
            }
            return .none
        }
    }
}
