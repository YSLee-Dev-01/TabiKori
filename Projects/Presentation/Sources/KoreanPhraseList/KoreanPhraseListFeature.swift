//
//  KoreanPhraseListFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 간단한 한국어(일본어 포함) 문구 전체 목록 화면. ToolBar 허브의 한국어 섹션에서 push 진입
@Reducer
public struct KoreanPhraseListFeature: Sendable {

    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase

    @ObservableState
    public struct State: Equatable {
        var phrases: [KoreanPhrase] = []
        var isLoading: Bool = false
        var hasLoadFailed: Bool = false
        fileprivate var hasStartedLoading: Bool = false
        @Presents var phraseDetailState: KoreanPhraseDetailFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case retryButtonTapped
        case phraseRowTapped(KoreanPhrase)
        case phrasesResult([KoreanPhrase])
        case phrasesFailed
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
                return self.fetchPhrasesEffect()
                    .cancellable(id: CancelID.fetchPhrases, cancelInFlight: true)

            case .retryButtonTapped:
                state.isLoading = true
                state.hasLoadFailed = false
                return self.fetchPhrasesEffect()
                    .cancellable(id: CancelID.fetchPhrases, cancelInFlight: true)

            case .phrasesResult(let phrases):
                state.phrases = phrases
                state.isLoading = false
                state.hasLoadFailed = false
                return .none

            case .phrasesFailed:
                state.isLoading = false
                state.hasLoadFailed = true
                return .none

            case .phraseRowTapped(let phrase):
                state.phraseDetailState = KoreanPhraseDetailFeature.State(phrase: phrase)
                return .none

            case .phraseDetail:
                return .none
            }
        }
        .ifLet(\.$phraseDetailState, action: \.phraseDetail) {
            KoreanPhraseDetailFeature()
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case fetchPhrases
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
}
