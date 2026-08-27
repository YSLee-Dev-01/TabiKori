//
//  TranslateSearchFeature.swift
//  Presentation
//
//  Created by Claude on 8/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain
import Resource

/// 검색 화면(Map/PlanDetailAddSpot/AddCustomPlace)에서 공통으로 쓰는 "일본어 검색어를 한국어로
/// 번역해 재검색" 기능을 캡슐화한 공용 하위 Reducer. 특정 화면 전용이 아니므로 화면 소유 Feature가
/// `Scope(state:action:)`로 조립해 사용한다
///
/// 실제 검색 실행(번역된 검색어로 재검색)은 이 Reducer가 직접 수행하지 않는다. 부모가
/// `Action.delegate(.retranslatedQueryReady)`를 받아 자신의 검색 로직으로 재검색을 트리거한다.
/// 이 Reducer는 번역 트리거 조건 검증, Toast 안내, Toast 액션탭 구독만 책임진다
@Reducer
public struct TranslateSearchFeature: Sendable {

    @Dependency(\.autoTranslateSearchUseCase) var autoTranslateSearchUseCase
    @Dependency(\.toastCenter) var toastCenter

    @ObservableState
    public struct State: Equatable {
        public var isAutoTranslateSearchEnabled: Bool = false
        /// View가 관찰해 Translation 프레임워크로 번역을 실행해야 하는 트리거. 값이 채워지면 View가 번역을 실행하고 결과를 돌려준다
        public var pendingTranslationQuery: String?
        /// 번역 유도 Toast를 띄웠을 때의 id. ToastCenter의 액션 탭 이벤트가 이 id와 일치할 때만 번역을 트리거한다
        fileprivate var translationToastId: UUID?
        /// Toast 액션탭 구독 이펙트를 화면 인스턴스별로 구분하기 위한 식별자.
        /// 이 Reducer가 여러 화면(Map/PlanDetailAddSpot/AddCustomPlace)에서 동시에 조립되므로,
        /// 고정된 CancelID만 쓰면 한 화면의 재구독이 다른 화면의 구독을 취소해버릴 수 있다
        fileprivate let subscriptionInstanceId = UUID()

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        /// 새 검색 시작/취소 시 남아있던 번역 유도 Toast id·대기 중인 번역 트리거를 초기화한다
        case reset
        case translateButtonRequested(query: String)
        case toastActionTapReceived(UUID)
        case searchCompleted(query: String, hasResults: Bool)
        case translationResultReceived(String)
        case translationFailed
        case delegate(Delegate)

        public enum Delegate: Equatable {
            /// 검색결과 없음 Toast의 번역 액션 버튼이 탭됨. 부모가 현재 검색어로 다시
            /// `.translateButtonRequested`를 보내 실제 검증/번역 트리거를 수행해야 한다
            case toastActionConfirmed
            /// 번역이 완료됨. 부모는 자신의 검색어 상태를 이 값으로 갱신하고 재검색해야 한다
            case retranslatedQueryReady(String)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isAutoTranslateSearchEnabled = self.autoTranslateSearchUseCase.isEnabled()
                return self.subscribeToastActionTapEffect(instanceId: state.subscriptionInstanceId)

            case .reset:
                state.translationToastId = nil
                state.pendingTranslationQuery = nil
                return .none

            case .translateButtonRequested(let query):
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedQuery.isEmpty == false else {
                    return self.showEmptyQueryGuideEffect()
                }
                guard trimmedQuery.containsJapanese else {
                    return self.showNonJapaneseInputGuideEffect()
                }
                state.pendingTranslationQuery = trimmedQuery
                return .none

            case .toastActionTapReceived(let toastId):
                guard state.translationToastId == toastId else { return .none }
                return .send(.delegate(.toastActionConfirmed))

            case .searchCompleted(let query, let hasResults):
                guard state.isAutoTranslateSearchEnabled,
                      query.isEmpty == false,
                      query.containsJapanese,
                      hasResults == false else { return .none }

                let toastId = UUID()
                state.translationToastId = toastId
                return .run { [toastCenter = self.toastCenter] _ in
                    toastCenter.show(ToastItem(
                        id: toastId,
                        message: Strings.Map.searchResultEmptyTitle,
                        type: .info,
                        actionButtonTitle: Strings.Map.translateAndSearchButtonTitle
                    ))
                }

            case .translationResultReceived(let translatedQuery):
                state.pendingTranslationQuery = nil
                guard translatedQuery.isEmpty == false else { return .none }
                return .send(.delegate(.retranslatedQueryReady(translatedQuery)))

            case .translationFailed:
                state.pendingTranslationQuery = nil
                return self.showTranslationFailedEffect()

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID: Hashable {
    case toastActionSubscription(UUID)
}

// MARK: - Method

private extension TranslateSearchFeature {
    func subscribeToastActionTapEffect(instanceId: UUID) -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] send in
            for await toastId in toastCenter.actionTapEvents {
                await send(.toastActionTapReceived(toastId))
            }
        }
        .cancellable(id: CancelID.toastActionSubscription(instanceId), cancelInFlight: true)
    }

    /// 검색어가 비어 있는 상태로 번역 버튼(아이콘 또는 Toast 액션)이 눌렸을 때, 조용히 무시하는 대신
    /// 안내 Toast를 띄운다
    func showEmptyQueryGuideEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(
                message: Strings.Map.translateSearchEmptyQueryGuideMessage,
                type: .info
            ))
        }
    }

    /// 검색어가 일본어를 포함하지 않는 상태(예: 한국어 입력)로 번역 버튼이 눌렸을 때, 번역을 시도하는 대신
    /// 이 기능이 일본어 입력 시에만 동작한다는 안내 Toast를 띄운다
    func showNonJapaneseInputGuideEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(
                message: Strings.Map.translateSearchNonJapaneseInputGuideMessage,
                type: .info
            ))
        }
    }

    /// 번역 실패 시 에러 Toast를 띄운다
    func showTranslationFailedEffect() -> Effect<Action> {
        .run { [toastCenter = self.toastCenter] _ in
            toastCenter.show(ToastItem(message: Strings.Map.translateFailedMessage, type: .error))
        }
    }
}
