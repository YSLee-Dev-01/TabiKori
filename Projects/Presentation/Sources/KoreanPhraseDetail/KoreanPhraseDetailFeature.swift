//
//  KoreanPhraseDetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

/// 한국어 문구 1건을 몰입감 있게 보여주는 가로모드 전용 상세 화면.
/// 화면 진입/이탈에 따른 실제 기기 방향 전환은 View 레이어(OrientationLock)에서 처리한다
@Reducer
public struct KoreanPhraseDetailFeature: Sendable {

    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let phrase: KoreanPhrase

        public init(phrase: KoreanPhrase) {
            self.phrase = phrase
        }
    }

    public enum Action: Equatable {
        case closeButtonTapped
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }
            }
        }
    }
}
