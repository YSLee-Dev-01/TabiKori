//
//  ToolBarFeature.swift
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

/// 툴박스 탭 루트 화면(허브). 준비물/환율/한국어 3개 섹션을 보여준다.
/// 환율 섹션은 ExchangeRateCalculatorFeature를 Scope로 내장해 그 자리에서 바로 계산할 수 있다
@Reducer
public struct ToolBarFeature: Sendable {

    @Dependency(\.toolBarItemUseCase) var toolBarItemUseCase
    @Dependency(\.koreanPhraseUseCase) var koreanPhraseUseCase
    @Dependency(\.shoppingItemUseCase) var shoppingItemUseCase

    @ObservableState
    public struct State: Equatable {
        var packingItems: [ToolBarItem] = []
        var isLoadingPacking: Bool = false
        var hasPackingLoadFailed: Bool = false
        fileprivate var hasStartedLoadingPacking: Bool = false

        var exchangeRateCalculatorState: ExchangeRateCalculatorFeature.State = .init()

        var phrases: [KoreanPhrase] = []
        var isLoadingPhrases: Bool = false
        var hasPhraseLoadFailed: Bool = false
        fileprivate var hasStartedLoadingPhrases: Bool = false

        var shoppingItems: [ShoppingItem] = []
        var isLoadingShopping: Bool = false
        var hasShoppingLoadFailed: Bool = false
        fileprivate var hasStartedLoadingShopping: Bool = false

        var scrollToTopTrigger: Int = 0

        @Presents var phraseDetailState: KoreanPhraseDetailFeature.State?
        @Presents var packingPlanPickerState: ToolBarPlanPickerFeature.State?
        @Presents var shoppingPlanPickerState: ShoppingPlanPickerFeature.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case scrollToTopRequested
        case packingRetryButtonTapped
        case phraseRetryButtonTapped
        case shoppingRetryButtonTapped
        case packingListButtonTapped
        case koreanPhraseListButtonTapped
        case shoppingListButtonTapped
        case phrasePreviewRowTapped(KoreanPhrase)
        case phraseCopyMenuTapped(KoreanPhrase)
        case packingPreviewRowTapped(ToolBarItem)
        case shoppingPreviewRowTapped(ShoppingItem)
        case packingItemsResult([ToolBarItem])
        case packingItemsFailed
        case phrasesResult([KoreanPhrase])
        case phrasesFailed
        case shoppingItemsResult([ShoppingItem])
        case shoppingItemsFailed
        case exchangeRateCalculator(ExchangeRateCalculatorFeature.Action)
        case phraseDetail(PresentationAction<KoreanPhraseDetailFeature.Action>)
        case packingPlanPicker(PresentationAction<ToolBarPlanPickerFeature.Action>)
        case shoppingPlanPicker(PresentationAction<ShoppingPlanPickerFeature.Action>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.exchangeRateCalculatorState, action: \.exchangeRateCalculator) {
            ExchangeRateCalculatorFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                var effects: [Effect<Action>] = [.send(.exchangeRateCalculator(.onAppear))]

                if state.hasStartedLoadingPacking == false {
                    state.hasStartedLoadingPacking = true
                    state.isLoadingPacking = true
                    state.hasPackingLoadFailed = false
                    effects.append(self.fetchPackingItemsEffect())
                }

                if state.hasStartedLoadingPhrases == false {
                    state.hasStartedLoadingPhrases = true
                    state.isLoadingPhrases = true
                    state.hasPhraseLoadFailed = false
                    effects.append(self.fetchPhrasesEffect())
                }

                if state.hasStartedLoadingShopping == false {
                    state.hasStartedLoadingShopping = true
                    state.isLoadingShopping = true
                    state.hasShoppingLoadFailed = false
                    effects.append(self.fetchShoppingItemsEffect())
                }

                return .merge(effects)

            case .scrollToTopRequested:
                state.scrollToTopTrigger += 1
                return .none

            case .packingRetryButtonTapped:
                state.isLoadingPacking = true
                state.hasPackingLoadFailed = false
                return self.fetchPackingItemsEffect()

            case .phraseRetryButtonTapped:
                state.isLoadingPhrases = true
                state.hasPhraseLoadFailed = false
                return self.fetchPhrasesEffect()

            case .shoppingRetryButtonTapped:
                state.isLoadingShopping = true
                state.hasShoppingLoadFailed = false
                return self.fetchShoppingItemsEffect()

            case .packingListButtonTapped, .koreanPhraseListButtonTapped, .shoppingListButtonTapped:
                return .none

            case .phrasePreviewRowTapped(let phrase):
                OrientationLock.shared.setMask(.landscape)
                state.phraseDetailState = KoreanPhraseDetailFeature.State(phrase: phrase)
                return .none

            case .phraseCopyMenuTapped(let phrase):
                UIPasteboard.general.string = phrase.korean
                return .none

            case .packingPreviewRowTapped(let item):
                state.packingPlanPickerState = ToolBarPlanPickerFeature.State(items: [item], alwaysAppend: true)
                return .none

            case .shoppingPreviewRowTapped(let item):
                state.shoppingPlanPickerState = ShoppingPlanPickerFeature.State(items: [item], alwaysAppend: true)
                return .none

            case .packingItemsResult(let items):
                state.packingItems = items
                state.isLoadingPacking = false
                state.hasPackingLoadFailed = false
                return .none

            case .packingItemsFailed:
                state.isLoadingPacking = false
                state.hasPackingLoadFailed = true
                return .none

            case .phrasesResult(let phrases):
                state.phrases = phrases
                state.isLoadingPhrases = false
                state.hasPhraseLoadFailed = false
                return .none

            case .phrasesFailed:
                state.isLoadingPhrases = false
                state.hasPhraseLoadFailed = true
                return .none

            case .shoppingItemsResult(let items):
                state.shoppingItems = items
                state.isLoadingShopping = false
                state.hasShoppingLoadFailed = false
                return .none

            case .shoppingItemsFailed:
                state.isLoadingShopping = false
                state.hasShoppingLoadFailed = true
                return .none

            case .exchangeRateCalculator:
                return .none

            case .phraseDetail:
                return .none

            case .packingPlanPicker(.presented(.savedToPlan)):
                state.packingPlanPickerState = nil
                return .none

            case .packingPlanPicker:
                return .none

            case .shoppingPlanPicker(.presented(.savedToPlan)):
                state.shoppingPlanPickerState = nil
                return .none

            case .shoppingPlanPicker:
                return .none
            }
        }
        .ifLet(\.$phraseDetailState, action: \.phraseDetail) {
            KoreanPhraseDetailFeature()
        }
        .ifLet(\.$packingPlanPickerState, action: \.packingPlanPicker) {
            ToolBarPlanPickerFeature()
        }
        .ifLet(\.$shoppingPlanPickerState, action: \.shoppingPlanPicker) {
            ShoppingPlanPickerFeature()
        }
    }
}

// MARK: - State

public extension ToolBarFeature.State {
    var packingPreviewItems: [ToolBarItem] {
        Array(self.packingItems.prefix(5))
    }

    var phrasePreviewItems: [KoreanPhrase] {
        Array(self.phrases.prefix(5))
    }

    var shoppingPreviewItems: [ShoppingItem] {
        Array(self.shoppingItems.prefix(5))
    }
}

// MARK: - Method

private extension ToolBarFeature {
    func fetchPackingItemsEffect() -> Effect<Action> {
        .run { [toolBarItemUseCase = self.toolBarItemUseCase] send in
            do {
                let items = try await toolBarItemUseCase.fetchMasterItems()
                await send(.packingItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "준비물 마스터 리스트 조회 실패: \(error.localizedDescription)")
                await send(.packingItemsFailed)
            }
        }
    }

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

    func fetchShoppingItemsEffect() -> Effect<Action> {
        .run { [shoppingItemUseCase = self.shoppingItemUseCase] send in
            do {
                let items = try await shoppingItemUseCase.fetchRecommendedItems()
                await send(.shoppingItemsResult(items))
            } catch {
                AppLogger.view.log(.error, "추천 쇼핑 리스트 조회 실패: \(error.localizedDescription)")
                await send(.shoppingItemsFailed)
            }
        }
    }
}
