//
//  RootFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct RootFeature {

    @ObservableState
    public struct State: Equatable {
        var tabBarState: TabBarFeature.State? = nil
        var toastQueue: [ToastItem] = []
        var currentToast: ToastItem? = nil

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case onboardingChecking
        case testBtnTapped
        case toastEventReceived(ToastItem)
        case toastQueueAdvanced
        case toastDismissed
        case tabBar(TabBarFeature.Action)
    }

    @Dependency(\.onboardingUseCase) var onboardingUsecase
    @Dependency(\.toastCenter) var toastCenter

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let onboardingEffect: Effect<Action> = state.tabBarState == nil ? .send(.onboardingChecking) : .none
                return .merge(onboardingEffect, self.subscribeToastEffect())

            case .onboardingChecking:
                if onboardingUsecase.isCompleted() {
                    state.tabBarState = .init()
                }
                return .none

            case .testBtnTapped:
                onboardingUsecase.markAsCompleted()
                return .send(.onboardingChecking)

            case .toastEventReceived(let item):
                state.toastQueue.append(item)
                if state.currentToast == nil {
                    return .send(.toastQueueAdvanced)
                }
                return .none

            case .toastQueueAdvanced:
                guard state.currentToast == nil, !state.toastQueue.isEmpty else { return .none }
                state.currentToast = state.toastQueue.removeFirst()
                return self.autoDismissEffect()

            case .toastDismissed:
                state.currentToast = nil
                return .send(.toastQueueAdvanced)

            case .tabBar:
                return .none
            }
        }
        .ifLet(\.tabBarState, action: \.tabBar) {
            TabBarFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case toastSubscription
    case toastAutoDismiss
}

// MARK: - Method

private extension RootFeature {
    func subscribeToastEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] send in
            for await item in toastCenter.events {
                await send(.toastEventReceived(item))
            }
        }
        .cancellable(id: CancelID.toastSubscription, cancelInFlight: true)
    }

    func autoDismissEffect() -> Effect<Action> {
        .run { send in
            try await Task.sleep(for: .seconds(2.5))
            await send(.toastDismissed)
        }
        .cancellable(id: CancelID.toastAutoDismiss, cancelInFlight: true)
    }
}
