//
//  SettingFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import MessageUI
import UIKit

import ComposableArchitecture
import Core
import Domain
import Resource

@Reducer
public struct SettingFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase
    @Dependency(\.dataResetUseCase) var dataResetUseCase
    @Dependency(\.autoScrollToTodayUseCase) var autoScrollToTodayUseCase
    @Dependency(\.autoTranslateSearchUseCase) var autoTranslateSearchUseCase
    @Dependency(\.toastCenter) var toastCenter

    @ObservableState
    public struct State: Equatable {
        var locationStatus: LocationAuthorizationStatus = .denied
        var isResetting: Bool = false
        var isAutoScrollToTodayEnabled: Bool = false
        var isAutoTranslateSearchEnabled: Bool = false
        var isMailComposePresented: Bool = false
        @Presents var infoState: SettingInfoFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case scenePhaseBecameActive
        case gpsRowTapped
        case resetRowTapped
        case autoScrollToTodayToggled(Bool)
        case autoTranslateSearchToggled(Bool)
        case etcRowTapped(SettingEtcItem)
        case testCrashRowTapped
        case mailComposeDismissed
        case resetResult(Bool)
        case resetCompleted
        case info(PresentationAction<SettingInfoFeature.Action>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case resetConfirmed
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear, .scenePhaseBecameActive:
                state.locationStatus = self.locationUseCase.checkAuthorization()
                state.isAutoScrollToTodayEnabled = self.autoScrollToTodayUseCase.isEnabled()
                state.isAutoTranslateSearchEnabled = self.autoTranslateSearchUseCase.isEnabled()
                return .none

            case .autoScrollToTodayToggled(let isEnabled):
                state.isAutoScrollToTodayEnabled = isEnabled
                self.autoScrollToTodayUseCase.setEnabled(isEnabled)
                return .none

            case .autoTranslateSearchToggled(let isEnabled):
                state.isAutoTranslateSearchEnabled = isEnabled
                self.autoTranslateSearchUseCase.setEnabled(isEnabled)
                return .none

            case .gpsRowTapped:
                return .run { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        AppLogger.view.log(.error, "설정 앱 URL 생성 실패")
                        return
                    }
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }

            case .resetRowTapped:
                guard state.isResetting == false else { return .none }
                state.alert = AlertState {
                    TextState(Strings.Setting.dataResetAlertTitle)
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState(Strings.Map.searchCancel)
                    }
                    ButtonState(role: .destructive, action: .resetConfirmed) {
                        TextState(Strings.Setting.dataResetAlertConfirmButton)
                    }
                } message: {
                    TextState(Strings.Setting.dataResetAlertMessage)
                }
                return .none

            case .alert(.presented(.resetConfirmed)):
                state.isResetting = true
                return self.resetAllEffect()

            case .alert:
                return .none

            case .etcRowTapped(let item):
                switch item.kind {
                case .staticText(let contentType):
                    state.infoState = SettingInfoFeature.State(contentType: contentType)
                    return .none

                case .mailCompose:
                    guard MFMailComposeViewController.canSendMail() else {
                        return .run { [toastCenter = self.toastCenter] _ in
                            toastCenter.show(ToastItem(message: Strings.Setting.mailNotAvailableMessage, type: .error))
                        }
                    }
                    state.isMailComposePresented = true
                    return .none

                case .openURL(let urlString):
                    return .run { _ in
                        guard let url = URL(string: urlString) else {
                            AppLogger.view.log(.error, "설정 링크 URL 생성 실패: \(urlString)")
                            return
                        }
                        await MainActor.run {
                            UIApplication.shared.open(url)
                        }
                    }

                case .versionDisplay, .disabled:
                    return .none
                }

            case .testCrashRowTapped:
                #if DEBUG
                AppLogger.triggerTestCrash()
                #endif
                return .none

            case .mailComposeDismissed:
                state.isMailComposePresented = false
                return .none

            case .resetResult(true):
                state.isResetting = false
                state.alert = AlertState {
                    TextState(Strings.Setting.dataResetSuccessAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                }
                return .send(.resetCompleted)

            case .resetResult(false):
                state.isResetting = false
                state.alert = AlertState {
                    TextState(Strings.Setting.dataResetFailureAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.Setting.dataResetFailureAlertMessage)
                }
                return .none

            case .resetCompleted:
                return .none

            case .info:
                return .none
            }
        }
        .ifLet(\.$infoState, action: \.info) {
            SettingInfoFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case reset
}

// MARK: - Method

private extension SettingFeature {
    func resetAllEffect() -> Effect<Action> {
        .run { [dataResetUseCase = self.dataResetUseCase] send in
            do {
                try await dataResetUseCase.resetAll()
                await send(.resetResult(true))
            } catch {
                AppLogger.view.log(.error, "데이터 초기화 실패: \(error.localizedDescription)")
                await send(.resetResult(false))
            }
        }
        .cancellable(id: CancelID.reset)
    }
}
