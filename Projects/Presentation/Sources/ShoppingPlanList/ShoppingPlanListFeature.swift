//
//  ShoppingPlanListFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 플랜에 저장된 쇼핑 리스트 체크리스트 화면. 항목 체크/해제는 낙관적으로 갱신 후 실패 시 되돌린다
@Reducer
public struct ShoppingPlanListFeature: Sendable {

    @Dependency(\.shoppingPlanItemUseCase) var shoppingPlanItemUseCase
    @Dependency(\.analyticsCenter) var analyticsCenter

    @ObservableState
    public struct State: Equatable {
        let plan: TravelPlan
        var items: [ShoppingPlanItem] = []
        var isLoading: Bool = false
        var isAdding: Bool = false
        var newItemTitle: String = ""
        var newItemNote: String = ""
        var isEditing: Bool = false
        var editSnapshot: [ShoppingPlanItem]?
        var isSaving: Bool = false
        fileprivate var hasStartedLoading: Bool = false

        public init(plan: TravelPlan) {
            self.plan = plan
        }

        var checkedCount: Int {
            self.items.filter(\.isChecked).count
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case itemTapped(id: UUID)
        case addButtonTapped
        case editButtonTapped
        case newItemSubmitted
        case editItemDeleted(at: IndexSet)
        case editCancelButtonTapped
        case editSaveButtonTapped
        case savedItemsResult([ShoppingPlanItem])
        case checkUpdateFailed(id: UUID, previous: Bool)
        case addItemFailed(id: UUID)
        case editSaveResult([ShoppingPlanItem]?)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                state.isLoading = true
                return self.fetchSavedItemsEffect(planId: state.plan.id)

            case .itemTapped(let id):
                guard state.isEditing == false else { return .none }
                guard let index = state.items.firstIndex(where: { $0.id == id }) else { return .none }
                let previous = state.items[index].isChecked
                state.items[index].isChecked.toggle()
                self.analyticsCenter.log(.shoppingItemChecked)
                return self.updateCheckedEffect(
                    planId: state.plan.id,
                    itemId: id,
                    isChecked: state.items[index].isChecked,
                    previous: previous
                )

            case .addButtonTapped:
                guard state.isEditing == false else { return .none }
                if state.isAdding {
                    state.isAdding = false
                    state.newItemTitle = ""
                    state.newItemNote = ""
                } else {
                    state.isAdding = true
                }
                return .none

            case .editButtonTapped:
                state.isAdding = false
                state.newItemTitle = ""
                state.newItemNote = ""
                if state.isEditing {
                    if let snapshot = state.editSnapshot {
                        state.items = snapshot
                    }
                    state.editSnapshot = nil
                    state.isEditing = false
                } else {
                    state.editSnapshot = state.items
                    state.isEditing = true
                }
                return .none

            case .newItemSubmitted:
                let title = state.newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard title.isEmpty == false else { return .none }
                let note = state.newItemNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let newItem = ShoppingPlanItem(
                    id: UUID(),
                    planId: state.plan.id,
                    order: state.items.count,
                    title: title,
                    note: note.isEmpty ? nil : note,
                    isChecked: false
                )
                state.items.append(newItem)
                state.newItemTitle = ""
                state.newItemNote = ""
                return self.replaceEffect(planId: state.plan.id, items: state.items, addedItemId: newItem.id)

            case .editItemDeleted(let indexSet):
                state.items.remove(atOffsets: indexSet)
                state.items = state.items.enumerated().map { index, item in
                    ShoppingPlanItem(id: item.id, planId: item.planId, order: index, title: item.title, note: item.note, isChecked: item.isChecked)
                }
                return self.deleteItemsEffect(planId: state.plan.id, items: state.items)

            case .editCancelButtonTapped:
                if let snapshot = state.editSnapshot {
                    state.items = snapshot
                }
                state.editSnapshot = nil
                state.isEditing = false
                state.isSaving = false
                return .cancel(id: CancelID.saveEditedItems)

            case .editSaveButtonTapped:
                guard state.isSaving == false else { return .none }
                state.isSaving = true
                return self.saveEditedItemsEffect(planId: state.plan.id, items: state.items)
                    .cancellable(id: CancelID.saveEditedItems)

            case .savedItemsResult(let items):
                state.items = items
                state.isLoading = false
                return .none

            case .checkUpdateFailed(let id, let previous):
                guard let index = state.items.firstIndex(where: { $0.id == id }) else { return .none }
                state.items[index].isChecked = previous
                return .none

            case .addItemFailed(let id):
                state.items.removeAll { $0.id == id }
                return .none

            case .editSaveResult(let items):
                state.isSaving = false
                if let items {
                    state.items = items
                    state.editSnapshot = nil
                    state.isEditing = false
                }
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case saveEditedItems
}

// MARK: - Method

private extension ShoppingPlanListFeature {
    func fetchSavedItemsEffect(planId: UUID) -> Effect<Action> {
        .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                let items = try await shoppingPlanItemUseCase.fetchSavedItems(planId: planId)
                await send(.savedItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 저장 목록 조회 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.savedItemsResult([]))
            }
        }
    }

    func updateCheckedEffect(planId: UUID, itemId: UUID, isChecked: Bool, previous: Bool) -> Effect<Action> {
        .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                try await shoppingPlanItemUseCase.updateChecked(planId: planId, itemId: itemId, isChecked: isChecked)
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 체크 상태 변경 실패 (planId: \(planId), itemId: \(itemId)): \(error.localizedDescription)")
                await send(.checkUpdateFailed(id: itemId, previous: previous))
            }
        }
    }

    func replaceEffect(planId: UUID, items: [ShoppingPlanItem], addedItemId: UUID) -> Effect<Action> {
        .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                try await shoppingPlanItemUseCase.replace(planId: planId, items: items)
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 항목 추가 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.addItemFailed(id: addedItemId))
            }
        }
    }

    /// 스와이프 삭제는 낙관적으로 처리한다: UI에서는 즉시 제거된 상태를 유지하고,
    /// 저장 실패 시에도 목록을 되돌리지 않으며 에러만 로깅한다
    func deleteItemsEffect(planId: UUID, items: [ShoppingPlanItem]) -> Effect<Action> {
        .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] _ in
            do {
                try await shoppingPlanItemUseCase.replace(planId: planId, items: items)
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 항목 삭제 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
            }
        }
    }

    func saveEditedItemsEffect(planId: UUID, items: [ShoppingPlanItem]) -> Effect<Action> {
        let reordered = items.enumerated().map { index, item in
            ShoppingPlanItem(id: item.id, planId: item.planId, order: index, title: item.title, note: item.note, isChecked: item.isChecked)
        }
        return .run { [shoppingPlanItemUseCase = self.shoppingPlanItemUseCase] send in
            do {
                try await shoppingPlanItemUseCase.replace(planId: planId, items: reordered)
                await send(.editSaveResult(reordered))
            } catch {
                AppLogger.view.log(.error, "쇼핑 리스트 편집 저장 실패 (planId: \(planId)): \(error.localizedDescription)")
                await send(.editSaveResult(nil))
            }
        }
    }
}
