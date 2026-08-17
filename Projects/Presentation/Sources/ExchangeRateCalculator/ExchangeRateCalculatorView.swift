//
//  ExchangeRateCalculatorView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct ExchangeRateCalculatorView: View {

    fileprivate enum ExchangeField: Hashable {
        case krw
        case jpy
    }

    @Bindable private var store: StoreOf<ExchangeRateCalculatorFeature>
    @FocusState private var focusedField: ExchangeField?

    public init(store: StoreOf<ExchangeRateCalculatorFeature>) {
        self.store = store
    }

    public var body: some View {
        self.calculatorCard()
            .onTapGesture {
                self.focusedField = nil
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension ExchangeRateCalculatorView {
    func calculatorCard() -> some View {
        TabiCard {
            VStack(spacing: 15) {
                HStack(spacing: 0) {
                    self.currencyAmountField(
                        flag: "🇰🇷",
                        code: "KRW",
                        symbol: "₩",
                        field: .krw,
                        text: self.$store.krwAmountText,
                        fractionDigits: 0,
                        valueColor: .tabiTextPrimary
                    )
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                        Text("=")
                            .font(.system(size: 12))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }

                    self.currencyAmountField(
                        flag: "🇯🇵",
                        code: "JPY",
                        symbol: "¥",
                        field: .jpy,
                        text: self.$store.jpyAmountText,
                        fractionDigits: 1,
                        valueColor: .tabiPrimary
                    )
                    .frame(maxWidth: .infinity)
                }

                if self.store.exchangeRateUpdatedAtTitle.isEmpty == false {
                    TabiLabel(
                        title: self.store.exchangeRateUpdatedAtTitle,
                        style: .captionS,
                        color: .tabiTextTertiary
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
    }

    func currencyAmountField(
        flag: String,
        code: String,
        symbol: String,
        field: ExchangeField,
        text: Binding<String>,
        fractionDigits: Int,
        valueColor: TabiColor
    ) -> some View {
        let isFocused = self.focusedField == field

        return VStack(spacing: 6) {
            Text(flag)
                .font(.system(size: 32))

            HStack(spacing: 2) {
                Text(symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(valueColor)

                ZStack {
                    TextField("0", text: text)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .opacity(isFocused ? 1 : 0.02)
                        .focused(self.$focusedField, equals: field)

                    if !isFocused {
                        Group {
                            if let value = Double(text.wrappedValue) {
                                Text(value, format: .number.precision(.fractionLength(fractionDigits)))
                            } else {
                                Text(text.wrappedValue)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: 70)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(valueColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TabiColor.tabiBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? valueColor : TabiColor.tabiBorder, lineWidth: isFocused ? 1.5 : 1)
            }

            Text(code)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(TabiColor.tabiTextTertiary)
                .tracking(0.8)
        }
    }
}

#Preview {
    ExchangeRateCalculatorView(
        store: Store(
            initialState: ExchangeRateCalculatorFeature.State(),
            reducer: { ExchangeRateCalculatorFeature() }
        )
    )
    .padding(20)
}
