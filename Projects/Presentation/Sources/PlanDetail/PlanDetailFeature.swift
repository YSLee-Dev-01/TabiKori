//
//  PlanDetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 일정 상세 화면. NavigationBar와 일자 선택 탭, 선택된 날짜의 스팟 목록 표시 + 스와이프 삭제를 담당한다
@Reducer
public struct PlanDetailFeature: Sendable {

    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase

    @ObservableState
    public struct State: Equatable {
        var plan: TravelPlan
        var travelPlanDetail: TravelPlanDetail?
        var selectedDayIndex: Int = 0
        fileprivate var hasStartedLoading: Bool = false
        @Presents var addSpotState: PlanDetailAddSpotFeature.State?

        public init(plan: TravelPlan, initialDayIndex: Int = 0) {
            self.plan = plan
            self.selectedDayIndex = min(max(initialDayIndex, 0), plan.dayCount - 1)
        }

        var selectedDaySpots: [TravelPlanDetailSpot] {
            guard let spots = self.travelPlanDetail?.spots else { return [] }
            return spots
                .filter { $0.dayIndex == self.selectedDayIndex }
                .sorted { $0.order < $1.order }
        }
    }

    public enum Action: Equatable {
        case onAppear
        case dayButtonTapped(index: Int)
        case spotDeleteButtonTapped(id: UUID)
        case addSpotButtonTapped
        case spotRowTapped(TravelPlanDetailSpot)
        case travelPlanDetailResult(TravelPlanDetail?)
        case spotDeleted(id: UUID)
        case addSpot(PresentationAction<PlanDetailAddSpotFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                return self.fetchTravelPlanDetailEffect(id: state.plan.id)

            case .dayButtonTapped(let index):
                state.selectedDayIndex = index
                return .none

            case .spotDeleteButtonTapped(let id):
                return self.removeSpotEffect(planId: state.plan.id, spotId: id)

            case .addSpotButtonTapped:
                guard state.plan.dayDates.indices.contains(state.selectedDayIndex) else { return .none }
                state.addSpotState = PlanDetailAddSpotFeature.State(
                    planId: state.plan.id,
                    dayIndex: state.selectedDayIndex,
                    date: state.plan.dayDates[state.selectedDayIndex],
                    detail: state.travelPlanDetail
                )
                return .none

            case .spotRowTapped:
                return .none

            case .travelPlanDetailResult(let detail):
                state.travelPlanDetail = detail
                return .none

            case .spotDeleted(let id):
                guard let detail = state.travelPlanDetail else { return .none }
                state.travelPlanDetail = TravelPlanDetail(
                    planId: detail.planId,
                    spots: detail.spots.filter { $0.id != id }
                )
                return .none

            case .addSpot(.presented(.spotAdded)):
                state.addSpotState = nil
                return self.fetchTravelPlanDetailEffect(id: state.plan.id)

            case .addSpot:
                return .none
            }
        }
        .ifLet(\.$addSpotState, action: \.addSpot) {
            PlanDetailAddSpotFeature()
        }
    }
}

// MARK: - Method

private extension PlanDetailFeature {
    func fetchTravelPlanDetailEffect(id: UUID) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                let detail = try await travelPlanDetailUseCase.fetch(planId: id)
                await send(.travelPlanDetailResult(detail))
            } catch {
                AppLogger.view.log(.error, "일정 상세(TravelPlanDetail) 조회 실패: \(error.localizedDescription)")
                await send(.travelPlanDetailResult(nil))
            }
        }
    }

    func removeSpotEffect(planId: UUID, spotId: UUID) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            do {
                try await travelPlanDetailUseCase.removeSpot(planId: planId, spotId: spotId)
                await send(.spotDeleted(id: spotId))
            } catch {
                AppLogger.view.log(.error, "일정 상세 스팟 삭제 실패 (planId: \(planId), spotId: \(spotId)): \(error.localizedDescription)")
            }
        }
    }
}
