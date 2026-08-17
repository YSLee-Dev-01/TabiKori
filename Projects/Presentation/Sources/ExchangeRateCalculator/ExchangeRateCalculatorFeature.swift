//
//  ExchangeRateCalculatorFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// KRW/JPY 상호 환산 계산기 화면. ToolBar 허브의 환율 섹션에서 push 진입
@Reducer
public struct ExchangeRateCalculatorFeature: Sendable {

    @Dependency(\.exchangeRateUseCase) var exchangeRateUseCase

    @ObservableState
    public struct State: Equatable {
        var krwAmountText: String = "1000"
        var jpyAmountText: String = "0"
        var exchangeRateUpdatedAtTitle: String = ""
        fileprivate var krwToJPYRate: Double = 0
        fileprivate var hasStartedLoading: Bool = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case exchangeRateResult(KRWToJPYRate)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.krwAmountText):
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * state.krwToJPYRate)
                }
                return .none

            case .binding(\.jpyAmountText):
                if let jpy = Double(state.jpyAmountText), state.krwToJPYRate != 0 {
                    state.krwAmountText = String(format: "%.0f", jpy / state.krwToJPYRate)
                }
                return .none

            case .binding:
                return .none

            case .onAppear:
                guard state.hasStartedLoading == false else { return .none }
                state.hasStartedLoading = true
                return self.fetchExchangeRateEffect()

            case .exchangeRateResult(let krwToJPYRate):
                state.krwToJPYRate = krwToJPYRate.rate
                state.exchangeRateUpdatedAtTitle = krwToJPYRate.updatedAt.exchangeRateUpdatedAtTitle
                if let krw = Double(state.krwAmountText) {
                    state.jpyAmountText = String(format: "%.1f", krw * krwToJPYRate.rate)
                }
                return .none
            }
        }
    }
}

// MARK: - Method

private extension ExchangeRateCalculatorFeature {
    func fetchExchangeRateEffect() -> Effect<Action> {
        .run { [exchangeRateUseCase = self.exchangeRateUseCase] send in
            do {
                let krwToJPYRate = try await exchangeRateUseCase.fetchKRWToJPYRate()
                await send(.exchangeRateResult(krwToJPYRate))
            } catch {
                AppLogger.view.log(.error, "환율 조회 실패: \(error.localizedDescription)")
            }
        }
    }
}
