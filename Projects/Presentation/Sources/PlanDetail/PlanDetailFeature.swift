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

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase

    @ObservableState
    public struct State: Equatable {
        let id: UUID
        var plan: TravelPlan?
        var travelPlanDetail: TravelPlanDetail?
        var selectedDayIndex: Int = 0
        fileprivate var hasStartedLoading: Bool = false

        public init(id: UUID, initialDayIndex: Int = 0) {
            self.id = id
            self.selectedDayIndex = initialDayIndex
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
        case planResult(TravelPlan?)
        case travelPlanDetailResult(TravelPlanDetail?)
        case spotDeleted(id: UUID)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                return .merge(
                    self.fetchPlanEffect(id: state.id),
                    self.fetchTravelPlanDetailEffect(id: state.id)
                )

            case .dayButtonTapped(let index):
                state.selectedDayIndex = index
                return .none

            case .spotDeleteButtonTapped(let id):
                return self.removeSpotEffect(planId: state.id, spotId: id)

            case .planResult(let plan):
                state.plan = plan
                if let plan {
                    state.selectedDayIndex = min(max(state.selectedDayIndex, 0), plan.dayCount - 1)
                }
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
            }
        }
    }
}

// MARK: - Method

private extension PlanDetailFeature {
    func fetchPlanEffect(id: UUID) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                let plans = try await travelPlanUseCase.fetch()
                await send(.planResult(plans.first(where: { $0.id == id })))
            } catch {
                AppLogger.view.log(.error, "일정 상세 조회 실패: \(error.localizedDescription)")
                await send(.planResult(nil))
            }
        }
    }

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
