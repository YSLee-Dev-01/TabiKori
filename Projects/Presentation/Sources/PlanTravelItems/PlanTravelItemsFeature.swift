//
//  PlanTravelItemsFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 플랜에 저장된 준비물 체크리스트 화면. 항목 체크/해제는 낙관적으로 갱신 후 실패 시 되돌린다
@Reducer
public struct PlanTravelItemsFeature: Sendable {

    @Dependency(\.travelItemUseCase) var travelItemUseCase

    @ObservableState
    public struct State: Equatable {
        let plan: TravelPlan
        var items: [TravelPlanItem] = []
        var isLoading: Bool = false
        fileprivate var hasStartedLoading: Bool = false

        public init(plan: TravelPlan) {
            self.plan = plan
        }

        var checkedCount: Int {
            self.items.filter(\.isChecked).count
        }
    }

    public enum Action: Equatable {
        case onAppear
        case itemTapped(id: UUID)
        case savedItemsResult([TravelPlanItem])
        case checkUpdateFailed(id: UUID, previous: Bool)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                state.isLoading = true
                return self.fetchSavedItemsEffect(planId: state.plan.id)

            case .itemTapped(let id):
                guard let index = state.items.firstIndex(where: { $0.id == id }) else { return .none }
                let previous = state.items[index].isChecked
                state.items[index].isChecked.toggle()
                return self.updateCheckedEffect(
                    planId: state.plan.id,
                    itemId: id,
                    isChecked: state.items[index].isChecked,
                    previous: previous
                )

            case .savedItemsResult(let items):
                state.items = items
                state.isLoading = false
                return .none

            case .checkUpdateFailed(let id, let previous):
                guard let index = state.items.firstIndex(where: { $0.id == id }) else { return .none }
                state.items[index].isChecked = previous
                return .none
            }
        }
    }
}

// MARK: - Method

private extension PlanTravelItemsFeature {
    func fetchSavedItemsEffect(planId: UUID) -> Effect<Action> {
        .run { [travelItemUseCase = self.travelItemUseCase] send in
            do {
                let items = try await travelItemUseCase.fetchSavedItems(planId: planId)
                await send(.savedItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "준비물 저장 목록 조회 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.savedItemsResult([]))
            }
        }
    }

    func updateCheckedEffect(planId: UUID, itemId: UUID, isChecked: Bool, previous: Bool) -> Effect<Action> {
        .run { [travelItemUseCase = self.travelItemUseCase] send in
            do {
                try await travelItemUseCase.updateChecked(planId: planId, itemId: itemId, isChecked: isChecked)
            } catch {
                AppLogger.view.log(.error, "준비물 체크 상태 변경 실패 (planId: \(planId), itemId: \(itemId)): \(error.localizedDescription)")
                await send(.checkUpdateFailed(id: itemId, previous: previous))
            }
        }
    }
}
