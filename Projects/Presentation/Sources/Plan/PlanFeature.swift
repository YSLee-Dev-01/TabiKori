//
//  PlanFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

// MARK: - PlanFeature

@Reducer
public struct PlanFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase

    @ObservableState
    public struct State: Equatable {
        var plans: [TravelPlan] = []
        var isLoading: Bool = false
        @Presents var addPlanState: AddTravelPlanFeature.State?

        public init() {}

        var ongoingPlans: [TravelPlan] { self.plans.filter { $0.section == .ongoing } }
        var upcomingPlans: [TravelPlan] { self.plans.filter { $0.section == .upcoming } }
        var pastPlans: [TravelPlan] { self.plans.filter { $0.section == .past } }
    }

    public enum Action: Equatable {
        case onAppear
        case addButtonTapped
        case planTapped(id: UUID)
        case plansResult([TravelPlan])
        case addPlan(PresentationAction<AddTravelPlanFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return self.fetchPlansEffect()

            case .addButtonTapped:
                state.addPlanState = AddTravelPlanFeature.State()
                return .none

            case .planTapped:
                return .none

            case .plansResult(let plans):
                state.plans = plans
                state.isLoading = false
                return .none

            case .addPlan(.presented(.saveResult(true))):
                state.addPlanState = nil
                return self.fetchPlansEffect()

            case .addPlan:
                return .none
            }
        }
        .ifLet(\.$addPlanState, action: \.addPlan) {
            AddTravelPlanFeature()
        }
    }
}

// MARK: - Method

private extension PlanFeature {
    func fetchPlansEffect() -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                let plans = try await travelPlanUseCase.fetch()
                await send(.plansResult(plans))
            } catch {
                AppLogger.view.log(.error, "일정 목록 조회 실패: \(error.localizedDescription)")
                await send(.plansResult([]))
            }
        }
    }
}
