//
//  PackingListFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 준비물 마스터 리스트 전체 화면. ToolBar 허브의 준비물 섹션에서 push 진입, 플랜에 저장하는 시트를 연다
@Reducer
public struct PackingListFeature: Sendable {

    @Dependency(\.toolBarItemUseCase) var toolBarItemUseCase

    @ObservableState
    public struct State: Equatable {
        var items: [ToolBarItem] = []
        var isLoading: Bool = false
        var hasLoadFailed: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var planPickerState: ToolBarPlanPickerFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case retryButtonTapped
        case saveToPlanButtonTapped
        case masterItemsResult([ToolBarItem])
        case masterItemsFailed
        case planPicker(PresentationAction<ToolBarPlanPickerFeature.Action>)
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
                return self.fetchMasterItemsEffect()
                    .cancellable(id: CancelID.fetchMasterItems, cancelInFlight: true)

            case .retryButtonTapped:
                state.isLoading = true
                state.hasLoadFailed = false
                return self.fetchMasterItemsEffect()
                    .cancellable(id: CancelID.fetchMasterItems, cancelInFlight: true)

            case .saveToPlanButtonTapped:
                guard state.items.isEmpty == false else { return .none }
                state.planPickerState = ToolBarPlanPickerFeature.State(items: state.items)
                return .none

            case .masterItemsResult(let items):
                state.items = items
                state.isLoading = false
                state.hasLoadFailed = false
                return .none

            case .masterItemsFailed:
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
            ToolBarPlanPickerFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchMasterItems
}

// MARK: - Method

private extension PackingListFeature {
    func fetchMasterItemsEffect() -> Effect<Action> {
        .run { [toolBarItemUseCase = self.toolBarItemUseCase] send in
            do {
                let items = try await toolBarItemUseCase.fetchMasterItems()
                await send(.masterItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "준비물 마스터 리스트 조회 실패: \(error.localizedDescription)")
                await send(.masterItemsFailed)
            }
        }
    }
}
