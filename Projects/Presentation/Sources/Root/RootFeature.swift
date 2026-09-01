//
//  RootFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

@Reducer
public struct RootFeature {

    @ObservableState
    public struct State: Equatable {
        var tabBarState: TabBarFeature.State? = nil
        var onboardingState: OnboardingFeature.State? = nil
        var currentToast: ToastItem? = nil
        fileprivate var pendingDeepLink: WidgetDeepLink? = nil

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case onboardingChecking
        case toastEventReceived(ToastItem)
        case toastDismissed
        case toastActionButtonTapped
        case openURLReceived(URL)
        case tabBar(TabBarFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }

    @Dependency(\.onboardingUseCase) var onboardingUsecase
    @Dependency(\.toastCenter) var toastCenter
    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase
    @Dependency(\.widgetSnapshotStore) var widgetSnapshotStore

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let onboardingEffect: Effect<Action> = state.tabBarState == nil ? .send(.onboardingChecking) : .none
                return .merge(onboardingEffect, self.subscribeToastEffect(), self.syncWidgetSnapshotEffect())

            case .onboardingChecking:
                if onboardingUsecase.isCompleted() {
                    state.tabBarState = .init()
                } else {
                    state.onboardingState = .init()
                }
                return .none

            case .onboarding(.delegate(.completed)):
                if onboardingUsecase.isCompleted() == false {
                    AppLogger.core.log(.error, "온보딩 완료 저장 실패")
                }
                state.onboardingState = nil
                state.tabBarState = .init()
                guard let pendingDeepLink = state.pendingDeepLink else { return .none }
                state.pendingDeepLink = nil
                return .send(.tabBar(.deepLinkReceived(pendingDeepLink)))

            case .toastEventReceived(let item):
                state.currentToast = item
                return self.autoDismissEffect()

            case .toastDismissed:
                state.currentToast = nil
                return .none

            case .toastActionButtonTapped:
                guard let toastId = state.currentToast?.id else { return .none }
                return .merge(
                    self.notifyToastActionTappedEffect(id: toastId),
                    .send(.toastDismissed)
                )

            case .openURLReceived(let url):
                guard let link = WidgetDeepLink(url: url) else {
                    AppLogger.view.log(.error, "위젯 딥링크 처리 불가: \(url)")
                    return .none
                }
                guard state.tabBarState != nil else {
                    state.pendingDeepLink = link
                    return .none
                }
                return .send(.tabBar(.deepLinkReceived(link)))

            case .tabBar:
                return .none

            case .onboarding:
                return .none
            }
        }
        .ifLet(\.tabBarState, action: \.tabBar) {
            TabBarFeature()
        }
        .ifLet(\.onboardingState, action: \.onboarding) {
            OnboardingFeature()
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

    func notifyToastActionTappedEffect(id: UUID) -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.notifyActionTapped(id: id)
        }
    }

    func syncWidgetSnapshotEffect() -> Effect<Action> {
        WidgetSnapshotSync.syncAllSnapshotsEffect(
            travelPlanUseCase: self.travelPlanUseCase,
            koreanPhraseUseCase: self.koreanPhraseUseCase,
            widgetSnapshotStore: self.widgetSnapshotStore
        )
    }
}
