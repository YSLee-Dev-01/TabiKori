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
    @Dependency(\.travelPlanDetailUseCase) var travelPlanDetailUseCase

    @ObservableState
    public struct State: Equatable {
        var plans: [TravelPlan] = []
        var spotCounts: [UUID: Int] = [:]
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
        case planTapped(plan: TravelPlan)
        case planDeleteButtonTapped(id: UUID)
        case plansResult([TravelPlan])
        case spotCountsResult([UUID: Int])
        case planDeleted(id: UUID)
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

            case .planDeleteButtonTapped(let id):
                return self.removePlanEffect(planId: id)

            case .plansResult(let plans):
                state.plans = plans
                state.isLoading = false
                return self.fetchSpotCountsEffect(plans: plans)

            case .spotCountsResult(let counts):
                state.spotCounts = counts
                return .none

            case .planDeleted(let id):
                state.plans.removeAll { $0.id == id }
                state.spotCounts.removeValue(forKey: id)
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

// MARK: - CancelID

private enum CancelID {
    case fetchPlans
    case fetchSpotCounts
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
        .cancellable(id: CancelID.fetchPlans, cancelInFlight: true)
    }

    func fetchSpotCountsEffect(plans: [TravelPlan]) -> Effect<Action> {
        .run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in
            var counts: [UUID: Int] = [:]
            await withTaskGroup(of: (UUID, Int).self) { group in
                for plan in plans {
                    group.addTask {
                        do {
                            let detail = try await travelPlanDetailUseCase.fetch(planId: plan.id)
                            return (plan.id, detail?.spots.count ?? 0)
                        } catch {
                            AppLogger.view.log(.error, "일정 스팟 개수 조회 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                            return (plan.id, 0)
                        }
                    }
                }
                for await (id, count) in group {
                    counts[id] = count
                }
            }
            await send(.spotCountsResult(counts))
        }
        .cancellable(id: CancelID.fetchSpotCounts, cancelInFlight: true)
    }

    func removePlanEffect(planId: UUID) -> Effect<Action> {
        .run { [travelPlanUseCase = self.travelPlanUseCase] send in
            do {
                try await travelPlanUseCase.remove(planId: planId)
                await send(.planDeleted(id: planId))
            } catch {
                AppLogger.view.log(.error, "일정 삭제 실패 (planId: \(planId)): \(error.localizedDescription)")
            }
        }
    }
}
