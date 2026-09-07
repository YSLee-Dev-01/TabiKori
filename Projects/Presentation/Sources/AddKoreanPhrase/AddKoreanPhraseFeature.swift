//
//  AddKoreanPhraseFeature.swift
//  Presentation
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

@Reducer
public struct AddKoreanPhraseFeature: Sendable {

    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase
    @Dependency(\.toastCenter) var toastCenter
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        var korean: String = ""
        var japanese: String = ""
        var pronunciation: String = ""
        var pendingTranslationJapanese: String?
        var isTranslating: Bool = false
        var isSaving: Bool = false

        @Presents var alert: AlertState<Action.Alert>?

        public init() {}

        var trimmedKorean: String {
            self.korean.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedJapanese: String {
            self.japanese.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var trimmedPronunciation: String {
            self.pronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isSaveEnabled: Bool {
            self.trimmedKorean.isEmpty == false && self.trimmedJapanese.isEmpty == false && self.isSaving == false
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeTapped
        case translateButtonTapped
        case saveButtonTapped
        case translationResultReceived(String)
        case translationFailed
        case saveResult(KoreanPhrase?)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .translateButtonTapped:
                guard state.trimmedJapanese.isEmpty == false else {
                    return self.showToastEffect(message: Strings.KoreanPhrase.translationEmptyJapaneseToast, type: .info)
                }
                state.pendingTranslationJapanese = state.trimmedJapanese
                state.isTranslating = true
                return .none

            case .translationResultReceived(let result):
                state.pendingTranslationJapanese = nil
                state.isTranslating = false
                guard result.isEmpty == false else { return .none }
                state.korean = result
                return .none

            case .translationFailed:
                state.pendingTranslationJapanese = nil
                state.isTranslating = false
                return self.showToastEffect(message: Strings.KoreanPhrase.translationFailedToast, type: .error)

            case .saveButtonTapped:
                guard state.isSaveEnabled else { return .none }
                state.isSaving = true
                return self.saveEffect(
                    korean: state.trimmedKorean,
                    japanese: state.trimmedJapanese,
                    pronunciation: state.trimmedPronunciation.isEmpty ? nil : state.trimmedPronunciation
                )

            case .saveResult(.some):
                state.isSaving = false
                return .none

            case .saveResult(.none):
                state.isSaving = false
                state.alert = AlertState {
                    TextState(Strings.Plan.saveFailedAlertTitle)
                } actions: {
                    ButtonState {
                        TextState(Strings.Plan.alertConfirm)
                    }
                } message: {
                    TextState(Strings.Plan.saveFailedAlertMessage)
                }
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - CancelID

private enum CancelID {
    case save
}

// MARK: - Method

private extension AddKoreanPhraseFeature {
    func saveEffect(korean: String, japanese: String, pronunciation: String?) -> Effect<Action> {
        .run { [koreanPhraseUseCase = self.koreanPhraseUseCase] send in
            do {
                let phrase = try await koreanPhraseUseCase.addCustomPhrase(korean: korean, japanese: japanese, pronunciation: pronunciation)
                await send(.saveResult(phrase))
            } catch {
                AppLogger.view.log(.error, "커스텀 한국어 문구 저장 실패: \(error.localizedDescription)")
                await send(.saveResult(nil))
            }
        }
        .cancellable(id: CancelID.save, cancelInFlight: true)
    }

    func showToastEffect(message: String, type: ToastType) -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(message: message, type: type))
        }
    }
}
