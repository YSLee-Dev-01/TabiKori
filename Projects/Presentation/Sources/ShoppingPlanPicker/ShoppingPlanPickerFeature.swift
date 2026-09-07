//
//  ShoppingPlanPickerFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/22/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

/// 추천 쇼핑 리스트를 저장할 플랜을 고르는 하단 sheet.
/// 이미 저장된 플랜을 다시 선택하면 덮어쓰기 확인 알림을 띄운 뒤 저장한다
@Reducer
public struct ShoppingPlanPickerFeature: Sendable {

    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.shoppingPlanItemUseCase) var shoppingPlanItemUseCase
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.analyticsCenter) var analyticsCenter

    @ObservableState
    public struct State: Equatable {
        let items: [ShoppingItem]
        /// true면 기존 저장 항목이 있어도 알럿 없이 항상 하단에 추가한다 (쇼핑 개별 셀 추가 진입 시 사용)
        let alwaysAppend: Bool
        var plans: [TravelPlan] = []
        var isLoading: Bool = false
        var isSaving: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        fileprivate var pendingExistingItems: [ShoppingPlanItem] = []
        @Presents var alert: AlertState<Action.Alert>?

        public init(items: [ShoppingItem], alwaysAppend: Bool = false) {
            self.items = items
            self.alwaysAppend = alwaysAppend
        }
    }

    public enum Action: Equatable {
        case onAppear
        case closeButtonTapped
        case planRowTapped(TravelPlan)
        case plansResult([TravelPlan])
        case existingItemsResult(plan: TravelPlan, existingItems: [ShoppingPlanItem])
        case saveFailed
        case savedToPlan
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case overwriteConfirmed(TravelPlan)
            case appendConfirmed(TravelPlan)
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

            case .existingItemsResult(let plan, let existingItems):
                guard existingItems.isEmpty == false else {
                    return self.saveEffect(planId: plan.id, items: state.items)
                }

                if state.alwaysAppend {
                    state.isSaving = true
                    return self.appendEffect(planId: plan.id, existingItems: existingItems, newItems: state.items)
                }

                state.isSaving = false
                state.pendingExistingItems = existingItems
                state.alert = AlertState {
                    TextState(Strings.Shopping.overwriteAlertTitle)
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState(Strings.ToolBar.overwriteAlertCancel)
                    }
                    ButtonState(action: .appendConfirmed(plan)) {
                        TextState(Strings.ToolBar.appendAlertConfirm)
                    }
                    ButtonState(role: .destructive, action: .overwriteConfirmed(plan)) {
                        TextState(Strings.ToolBar.overwriteAlertConfirm)
                    }
                } message: {
                    TextState(Strings.Shopping.overwriteAlertMessage)
                }
                return .none

            case .alert(.presented(.overwriteConfirmed(let plan))):
                state.isSaving = true
                return self.saveEffect(planId: plan.id, items: state.items)

            case .alert(.presented(.appendConfirmed(let plan))):
                state.isSaving = true
                return self.appendEffect(planId: plan.id, existingItems: state.pendingExistingItems, newItems: state.items)

            case .alert:
                return .none

            case .saveFailed:
                state.isSaving = false
                state.alert = AlertState {
                    TextState(Strings.ToolBar.saveFailedDescription)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                }
                return .none

            case .savedToPlan:
                self.analyticsCenter.log(.shoppingPlanCreated)
                return .run { [dismiss = self.dismiss] _ in await dismiss() }
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Method

private extension ShoppingPlanPickerFeature {
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
        .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                let existingItems = try await shoppingPlanItemUseCase.fetchSavedItems(planId: plan.id)
                await send(.existingItemsResult(plan: plan, existingItems: existingItems))
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 저장 여부 조회 실패 (planId: \(plan.id)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }

    func saveEffect(planId: UUID, items: [ShoppingItem]) -> Effect<Action> {
        let newItems = items.enumerated().map { index, item in
            ShoppingPlanItem(id: UUID(), planId: planId, order: index, title: item.title, note: item.note, isChecked: false)
        }

        return .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                try await shoppingPlanItemUseCase.replace(planId: planId, items: newItems)
                await send(.savedToPlan)
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }

    /// 기존 저장 항목(existingItems) 뒤에 신규 항목(newItems)을 이어붙여 order를 재계산한 뒤 전체 교체 저장한다
    func appendEffect(planId: UUID, existingItems: [ShoppingPlanItem], newItems: [ShoppingItem]) -> Effect<Action> {
        let baseOrder = existingItems.count
        let appendedItems = newItems.enumerated().map { index, item in
            ShoppingPlanItem(id: UUID(), planId: planId, order: baseOrder + index, title: item.title, note: item.note, isChecked: false)
        }
        let combinedItems = existingItems + appendedItems

        return .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                try await shoppingPlanItemUseCase.replace(planId: planId, items: combinedItems)
                await send(.savedToPlan)
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 추가 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.saveFailed)
            }
        }
    }
}
