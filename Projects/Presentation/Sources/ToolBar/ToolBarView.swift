//
//  ToolBarView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// 툴박스 탭 루트 화면(허브). 준비물/환율/한국어 3개 섹션을 스크롤로 순서대로 보여준다
public struct ToolBarView: View {

    @Bindable private var store: StoreOf<ToolBarFeature>

    public init(store: StoreOf<ToolBarFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                self.packingSection()
                self.exchangeRateSection()
                self.koreanPhraseSection()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.ToolBar.hubTitle)
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - Common

private extension ToolBarView {
    func chevronIcon() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(TabiColor.tabiTextTertiary)
    }

    func sectionMoreButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                TabiLabel(title: Strings.ToolBar.seeAllButton, style: .bodySBold, color: .tabiTextSecondary)
                self.chevronIcon()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(TabiPressStyle())
    }
}

// MARK: - Packing Section

private extension ToolBarView {
    @ViewBuilder
    func packingSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.ToolBar.packingSectionTitle, style: .titleM, color: .tabiTextPrimary)

            if self.store.isLoadingPacking {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if self.store.hasPackingLoadFailed {
                TabiRetryableEmptyState(description: Strings.ToolBar.loadFailedDescription) {
                    self.store.send(.packingRetryButtonTapped)
                }
            } else if self.store.packingItems.isEmpty {
                TabiEmptyState(
                    systemImageName: "shippingbox",
                    title: Strings.ToolBar.itemEmptyTitle,
                    description: Strings.ToolBar.itemEmptyDescription,
                    style: .card
                )
            } else {
                TabiCard {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(self.store.packingPreviewItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                            self.packingPreviewRow(item)
                        }
                    }
                }
            }

            self.sectionMoreButton {
                self.store.send(.packingListButtonTapped)
            }
        }
    }

    func packingPreviewRow(_ item: ToolBarItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiLabel(title: item.title, style: .bodyMBold, color: .tabiTextPrimary)
            if let note = item.note, note.isEmpty == false {
                TabiLabel(title: note, style: .captionM, color: .tabiTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

// MARK: - Exchange Rate Section

private extension ToolBarView {
    func exchangeRateSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.ToolBar.exchangeRateSectionTitle, style: .titleM, color: .tabiTextPrimary)

            ExchangeRateCalculatorView(
                store: self.store.scope(state: \.exchangeRateCalculatorState, action: \.exchangeRateCalculator)
            )
        }
    }
}

// MARK: - Korean Phrase Section

private extension ToolBarView {
    @ViewBuilder
    func koreanPhraseSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.KoreanPhrase.sectionTitle, style: .titleM, color: .tabiTextPrimary)

            if self.store.isLoadingPhrases {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if self.store.hasPhraseLoadFailed {
                TabiRetryableEmptyState(description: Strings.KoreanPhrase.loadFailedDescription) {
                    self.store.send(.phraseRetryButtonTapped)
                }
            } else if self.store.phrases.isEmpty {
                TabiEmptyState(
                    systemImageName: "text.bubble",
                    title: Strings.KoreanPhrase.emptyTitle,
                    description: Strings.KoreanPhrase.emptyDescription,
                    style: .card
                )
            } else {
                TabiCard {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(self.store.phrasePreviewItems.enumerated()), id: \.element.id) { index, phrase in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                            self.phrasePreviewRow(phrase)
                        }
                    }
                }
            }

            self.sectionMoreButton {
                self.store.send(.koreanPhraseListButtonTapped)
            }
        }
    }

    func phrasePreviewRow(_ phrase: KoreanPhrase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiLabel(title: phrase.korean, style: .bodyMBold, color: .tabiTextPrimary)
            TabiLabel(title: phrase.japanese, style: .bodyS, color: .tabiTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

#Preview {
    let mockToolBarItemUseCase: TestToolBarItemUseCase = {
        let useCase = TestToolBarItemUseCase()
        useCase.masterItems = [
            ToolBarItem(id: "passport", order: 0, title: "パスポート", note: "有効期限を確認"),
            ToolBarItem(id: "charger", order: 1, title: "充電器", note: nil)
        ]
        return useCase
    }()

    let mockKoreanPhraseUseCase: TestKoreanPhraseUseCase = {
        let useCase = TestKoreanPhraseUseCase()
        useCase.phrases = [
            KoreanPhrase(id: "hello", order: 0, korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ")
        ]
        return useCase
    }()

    ToolBarView(
        store: Store(
            initialState: ToolBarFeature.State(),
            reducer: { ToolBarFeature() },
            withDependencies: { dependency in
                dependency.toolBarItemUseCase = mockToolBarItemUseCase
                dependency.koreanPhraseUseCase = mockKoreanPhraseUseCase
            }
        )
    )
}
