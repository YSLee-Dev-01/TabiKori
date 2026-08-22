//
//  ShoppingListFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/22/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 추천 쇼핑 리스트 전체 화면. ToolBar 허브의 쇼핑 섹션에서 push 진입, 플랜에 저장하는 시트를 연다
@Reducer
public struct ShoppingListFeature: Sendable {

    @Dependency(\.shoppingItemUseCase) var shoppingItemUseCase

    @ObservableState
    public struct State: Equatable {
        var items: [ShoppingItem] = []
        var isLoading: Bool = false
        var hasLoadFailed: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var planPickerState: ShoppingPlanPickerFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case retryButtonTapped
        case saveToPlanButtonTapped
        case itemRowTapped(ShoppingItem)
        case itemsResult([ShoppingItem])
        case itemsFailed
        case planPicker(PresentationAction<ShoppingPlanPickerFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                state.isLoading = true
                state.hasLoadFailed = false
                return self.fetchItemsEffect()
                    .cancellable(id: CancelID.fetchItems, cancelInFlight: true)

            case .retryButtonTapped:
                state.isLoading = true
                state.hasLoadFailed = false
                return self.fetchItemsEffect()
                    .cancellable(id: CancelID.fetchItems, cancelInFlight: true)

            case .saveToPlanButtonTapped:
                guard state.items.isEmpty == false else { return .none }
                state.planPickerState = ShoppingPlanPickerFeature.State(items: state.items)
                return .none

            case .itemRowTapped(let item):
                state.planPickerState = ShoppingPlanPickerFeature.State(items: [item], alwaysAppend: true)
                return .none

            case .itemsResult(let items):
                state.items = items
                state.isLoading = false
                state.hasLoadFailed = false
                return .none

            case .itemsFailed:
                state.isLoading = false
                state.hasLoadFailed = true
                return .none

            case .planPicker(.presented(.savedToPlan)):
                state.planPickerState = nil
                return .none

            case .planPicker:
                return .none
            }
        }
        .ifLet(\.$planPickerState, action: \.planPicker) {
            ShoppingPlanPickerFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchItems
}

// MARK: - Method

private extension ShoppingListFeature {
    func fetchItemsEffect() -> Effect<Action> {
        .run { [shoppingItemUseCase = self.shoppingItemUseCase] send in
            do {
                let items = try await shoppingItemUseCase.fetchRecommendedItems()
                await send(.itemsResult(items))
            } catch {
                AppLogger.view.log(.error, "추천 쇼핑 리스트 조회 실패: \(error.localizedDescription)")
                await send(.itemsFailed)
            }
        }
    }
}
