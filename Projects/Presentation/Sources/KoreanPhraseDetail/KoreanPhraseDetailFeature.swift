//
//  KoreanPhraseDetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// 한국어 문구 1건을 몰입감 있게 보여주는 가로모드 전용 상세 화면.
/// 실제 화면 회전 요청(requestGeometryUpdate)은 View 레이어(OrientationLock)에서 처리하되,
/// OrientationLock 마스크 자체는 dismiss 트랜지션이 시작되기 전인 여기서 미리 portrait로 되돌려
/// supportedInterfaceOrientationsFor가 트랜지션 시작 시점에 이미 portrait를 반환하도록 한다
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
                OrientationLock.shared.setMask(.portrait)
                return .run { [dismiss = self.dismiss] _ in await dismiss() }
            }
        }
    }
}
