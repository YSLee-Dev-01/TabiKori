//
//  TravelItemsPlanPickerFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

/// 준비물 마스터 리스트를 저장할 플랜을 고르는 하단 sheet.
/// 이미 저장된 플랜을 다시 선택하면 덮어쓰기 확인 알림을 띄운 뒤 저장한다
@Reducer
public struct TravelItemsPlanPickerFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.travelItemUseCase) var travelItemUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let items: [TravelItem]
        var plans: [TravelPlan] = []
        var isLoading: Bool = false
        var isSaving: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        public init(items: [TravelItem]) {
            self.items = items
        }
    }

    public enum Action: Equatable {
        case onAppear
        case closeButtonTapped
        case planRowTapped(TravelPlan)
        case plansResult([TravelPlan])
        case existingItemsResult(plan: TravelPlan, hasSaved: Bool)
        case saveFailed
        case savedToPlan
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case overwriteConfirmed(TravelPlan)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                state.isLoading = true
                return self.fetchPlansEffect()

            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .planRowTapped(let plan):
                guard state.isSaving == false else { return .none }
                state.isSaving = true
                return self.checkExistingItemsEffect(plan: plan)

            case .plansResult(let plans):
                state.plans = plans
                state.isLoading = false
                return .none

            case .existingItemsResult(let plan, let hasSaved):
                guard hasSaved else {
                    return self.saveEffect(planId: plan.id, items: state.items)
                }
                state.isSaving = false
                state.alert = AlertState {
                    TextState(Strings.TravelItems.overwriteAlertTitle)
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState(Strings.TravelItems.overwriteAlertCancel)
                    }
                    ButtonState(role: .destructive, action: .overwriteConfirmed(plan)) {
                        TextState(Strings.TravelItems.overwriteAlertConfirm)
                    }
                } message: {
                    TextState(Strings.TravelItems.overwriteAlertMessage)
                }
                return .none

            case .alert(.presented(.overwriteConfirmed(let plan))):
                state.isSaving = true
                return self.saveEffect(planId: plan.id, items: state.items)

            case .alert:
                return .none

            case .saveFailed:
                state.isSaving = false
                state.alert = AlertState {
                    TextState(Strings.TravelItems.saveFailedDescription)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                }
                return .none

            case .savedToPlan:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Method

private extension TravelItemsPlanPickerFeature {
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

    func checkExistingItemsEffect(plan: TravelPlan) -> Effect<Action> {
        .run { [travelItemUseCase = self.travelItemUseCase] send in
            do {
                let existingItems = try await travelItemUseCase.fetchSavedItems(planId: plan.id)
                await send(.existingItemsResult(plan: plan, hasSaved: existingItems.isEmpty == false))
            } catch {
                AppLogger.view.log(.error, "준비물 저장 여부 조회 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }

    func saveEffect(planId: UUID, items: [TravelItem]) -> Effect<Action> {
        .run { [travelItemUseCase = self.travelItemUseCase] send in
            do {
                try await travelItemUseCase.save(planId: planId, items: items)
                await send(.savedToPlan)
            } catch {
                AppLogger.view.log(.error, "준비물 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }
}
