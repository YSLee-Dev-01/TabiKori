//
//  SettingFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import UIKit

import ComposableArchitecture
import Core
import Domain
import Resource

@Reducer
public struct SettingFeature: Sendable {

    @Dependency(\.locationUseCase) var locationUseCase
    @Dependency(\.dataResetUseCase) var dataResetUseCase

    @ObservableState
    public struct State: Equatable {
        var locationStatus: LocationAuthorizationStatus = .denied
        var isResetting: Bool = false
        @Presents var infoState: SettingInfoFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case scenePhaseBecameActive
        case gpsRowTapped
        case resetRowTapped
        case etcRowTapped(SettingEtcItem)
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

                case .versionDisplay, .disabled:
                    break
                }
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
