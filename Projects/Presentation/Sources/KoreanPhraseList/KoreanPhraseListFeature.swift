//
//  KoreanPhraseListFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import UIKit

import ComposableArchitecture
import Core
import Domain

/// 간단한 한국어(일본어 포함) 문구 전체 목록 화면. ToolBar 허브의 한국어 섹션에서 push 진입
@Reducer
public struct KoreanPhraseListFeature: Sendable {

    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase
    @Dependency(\.analyticsCenter) var analyticsCenter

    @ObservableState
    public struct State: Equatable {
        var phrases: [KoreanPhrase] = []
        var customPhrases: [KoreanPhrase] = []
        var isLoading: Bool = false
        var hasLoadFailed: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var addPhraseState: AddKoreanPhraseFeature.State?
        @Presents var phraseDetailState: KoreanPhraseDetailFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case retryButtonTapped
        case addButtonTapped
        case phraseRowTapped(KoreanPhrase)
        case phraseCopyMenuTapped(KoreanPhrase)
        case customPhraseDeleted(id: String)
        case phrasesResult([KoreanPhrase])
        case phrasesFailed
        case customPhrasesResult([KoreanPhrase])
        case addPhrase(PresentationAction<AddKoreanPhraseFeature.Action>)
        case phraseDetail(PresentationAction<KoreanPhraseDetailFeature.Action>)
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
                return .merge(
                    self.fetchPhrasesEffect()
                        .cancellable(id: CancelID.fetchPhrases, cancelInFlight: true),
                    self.fetchCustomPhrasesEffect()
                        .cancellable(id: CancelID.fetchCustomPhrases, cancelInFlight: true)
                )

            case .retryButtonTapped:
                state.isLoading = true
                state.hasLoadFailed = false
                return self.fetchPhrasesEffect()
                    .cancellable(id: CancelID.fetchPhrases, cancelInFlight: true)

            case .addButtonTapped:
                state.addPhraseState = AddKoreanPhraseFeature.State()
                return .none

            case .phrasesResult(let phrases):
                state.phrases = phrases
                state.isLoading = false
                state.hasLoadFailed = false
                return .none

            case .phrasesFailed:
                state.isLoading = false
                state.hasLoadFailed = true
                return .none

            case .customPhrasesResult(let phrases):
                state.customPhrases = phrases
                return .none

            case .phraseRowTapped(let phrase):
                self.analyticsCenter.log(.koreanPhraseViewed(phraseId: phrase.id))
                OrientationLock.shared.setMask(.landscape)
                state.phraseDetailState = KoreanPhraseDetailFeature.State(phrase: phrase)
                return .none

            case .phraseCopyMenuTapped(let phrase):
                UIPasteboard.general.string = phrase.korean
                return .none

            case .customPhraseDeleted(let id):
                state.customPhrases.removeAll { $0.id == id }
                return self.deleteCustomPhraseEffect(id: id)

            case .addPhrase(.presented(.saveResult(.some(let phrase)))):
                state.customPhrases.insert(phrase, at: 0)
                state.addPhraseState = nil
                return .none

            case .addPhrase:
                return .none

            case .phraseDetail:
                return .none
            }
        }
        .ifLet(\.$addPhraseState, action: \.addPhrase) {
            AddKoreanPhraseFeature()
        }
        .ifLet(\.$phraseDetailState, action: \.phraseDetail) {
            KoreanPhraseDetailFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchPhrases
    case fetchCustomPhrases
}

// MARK: - Method

private extension KoreanPhraseListFeature {
    func fetchPhrasesEffect() -> Effect<Action> {
        .run { [koreanPhraseUseCase = self.koreanPhraseUseCase] send in
            do {
                let phrases = try await koreanPhraseUseCase.fetchPhrases()
                await send(.phrasesResult(phrases))
            } catch {
                AppLogger.view.log(.error, "한국어 문구 리스트 조회 실패: \(error.localizedDescription)")
                await send(.phrasesFailed)
            }
        }
    }

    func fetchCustomPhrasesEffect() -> Effect<Action> {
        .run { [koreanPhraseUseCase = self.koreanPhraseUseCase] send in
            do {
                let phrases = try await koreanPhraseUseCase.fetchCustomPhrases()
                await send(.customPhrasesResult(phrases))
            } catch {
                AppLogger.view.log(.error, "커스텀 한국어 문구 목록 조회 실패: \(error.localizedDescription)")
                await send(.customPhrasesResult([]))
            }
        }
    }

    /// 스와이프 삭제는 낙관적으로 처리한다: UI에서는 즉시 제거된 상태를 유지하고,
    /// 저장 실패 시에도 목록을 되돌리지 않으며 에러만 로깅한다
    func deleteCustomPhraseEffect(id: String) -> Effect<Action> {
        .run { [koreanPhraseUseCase = self.koreanPhraseUseCase] _ in
            do {
                try await koreanPhraseUseCase.deleteCustomPhrase(id: id)
            } catch {
                AppLogger.view.log(.error, "커스텀 한국어 문구 삭제 실패 (id: \(id)): \(error.localizedDescription)")
            }
        }
    }
}
