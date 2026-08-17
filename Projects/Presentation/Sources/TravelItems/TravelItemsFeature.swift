//
//  TravelItemsFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 툴박스 탭 루트 화면. Firebase에서 받아온 준비물 마스터 리스트를 보여주고, 플랜에 저장하는 시트를 연다
@Reducer
public struct TravelItemsFeature: Sendable {

    @Dependency(\.travelItemUseCase) var travelItemUseCase

    @ObservableState
    public struct State: Equatable {
        var items: [TravelItem] = []
        var isLoading: Bool = false
        var hasLoadFailed: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var planPickerState: TravelItemsPlanPickerFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case retryButtonTapped
        case saveToPlanButtonTapped
        case masterItemsResult([TravelItem])
        case masterItemsFailed
        case planPicker(PresentationAction<TravelItemsPlanPickerFeature.Action>)
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
                state.planPickerState = TravelItemsPlanPickerFeature.State(items: state.items)
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
            TravelItemsPlanPickerFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchMasterItems
}

// MARK: - Method

private extension TravelItemsFeature {
    func fetchMasterItemsEffect() -> Effect<Action> {
        .run { [travelItemUseCase = self.travelItemUseCase] send in
            do {
                let items = try await travelItemUseCase.fetchMasterItems()
                await send(.masterItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "준비물 마스터 리스트 조회 실패: \(error.localizedDescription)")
                await send(.masterItemsFailed)
            }
        }
    }
}
