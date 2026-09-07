//
//  RootFeature.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import UIKit

import ComposableArchitecture
import Core
import Domain
import Resource

@Reducer
public struct RootFeature {

    @ObservableState
    public struct State: Equatable {
        var tabBarState: TabBarFeature.State? = nil
        var onboardingState: OnboardingFeature.State? = nil
        var currentToast: ToastItem? = nil
        fileprivate var pendingDeepLink: WidgetDeepLink? = nil
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var noticePopupState: NoticePopupFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case onboardingChecking
        case appUpdateChecking
        case appUpdateResult(AppUpdateInfo?)
        case noticePopupChecking
        case noticePopupResult(Announcement?)
        case toastEventReceived(ToastItem)
        case toastDismissed
        case toastActionButtonTapped
        case openURLReceived(URL)
        case tabBar(TabBarFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case alert(PresentationAction<Alert>)
        case noticePopup(PresentationAction<NoticePopupFeature.Action>)

        public enum Alert: Equatable {
            case updateButtonTapped
        }
    }

    @Dependency(\.onboardingUseCase) var onboardingUsecase
    @Dependency(\.toastCenter) var toastCenter
    @Dependency(\.travelPlanUseCase) var travelPlanUseCase
    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase
    @Dependency(\.widgetSnapshotStore) var widgetSnapshotStore
    @Dependency(\.appUpdateUseCase) var appUpdateUseCase
    @Dependency(\.noticePopupUseCase) var noticePopupUseCase

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let onboardingEffect: Effect<Action> = state.tabBarState == nil ? .send(.onboardingChecking) : .none
                return .merge(
                    onboardingEffect,
                    self.subscribeToastEffect(),
                    self.syncWidgetSnapshotEffect(),
                    .send(.appUpdateChecking)
                )

            case .onboardingChecking:
                if onboardingUsecase.isCompleted() {
                    state.tabBarState = .init()
                } else {
                    state.onboardingState = .init()
                }
                return .none

            case .appUpdateChecking:
                return self.fetchAppUpdateInfoEffect()

            case .appUpdateResult(let info):
                guard let info else { return .send(.noticePopupChecking) }

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                guard currentVersion.isVersionLower(than: info.minimumVersion) else {
                    return .send(.noticePopupChecking)
                }

                state.alert = AlertState {
                    TextState(Strings.AppUpdate.alertTitle)
                } actions: {
                    ButtonState(action: .updateButtonTapped) {
                        TextState(Strings.AppUpdate.updateButtonTitle)
                    }
                } message: {
                    TextState(Strings.AppUpdate.alertMessage)
                }
                return .none

            case .noticePopupChecking:
                return self.fetchActiveNoticePopupEffect()

            case .noticePopupResult(let announcement):
                guard let announcement else { return .none }
                state.noticePopupState = NoticePopupFeature.State(announcement: announcement)
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

            case .tabBar(.delegate(.dataResetCompleted)):
                state.tabBarState = nil
                state.onboardingState = .init()
                return .none

            case .tabBar:
                return .none

            case .onboarding:
                return .none

            case .alert(.presented(.updateButtonTapped)):
                return self.openAppStoreEffect()

            case .alert:
                return .none

            case .noticePopup:
                return .none
            }
        }
        .ifLet(\.tabBarState, action: \.tabBar) {
            TabBarFeature()
        }
        .ifLet(\.onboardingState, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$noticePopupState, action: \.noticePopup) {
            NoticePopupFeature()
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

    func fetchAppUpdateInfoEffect() -> Effect<Action> {
        .run { [appUpdateUseCase = self.appUpdateUseCase] send in
            do {
                let info = try await appUpdateUseCase.fetchAppUpdateInfo()
                await send(.appUpdateResult(info))
            } catch {
                AppLogger.view.log(.error, "강제 업데이트 정보 조회 실패: \(error.localizedDescription)")
                await send(.appUpdateResult(nil))
            }
        }
    }

    func fetchActiveNoticePopupEffect() -> Effect<Action> {
        .run { [noticePopupUseCase = self.noticePopupUseCase] send in
            do {
                guard let announcement = try await noticePopupUseCase.fetchActiveAnnouncement(),
                      noticePopupUseCase.isDismissedToday(id: announcement.id) == false else {
                    await send(.noticePopupResult(nil))
                    return
                }
                await send(.noticePopupResult(announcement))
            } catch {
                AppLogger.view.log(.error, "팝업 공지 조회 실패: \(error.localizedDescription)")
                await send(.noticePopupResult(nil))
            }
        }
    }

    func openAppStoreEffect() -> Effect<Action> {
        .run { _ in
            guard let url = URL(string: TabiURL.appStoreUpdatePage) else {
                AppLogger.view.log(.error, "App Store URL 생성 실패")
                return
            }
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    }
}
