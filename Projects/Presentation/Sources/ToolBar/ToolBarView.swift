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

    private static let topAnchorID = "toolBarTop"

    @Bindable private var store: StoreOf<ToolBarFeature>

    public init(store: StoreOf<ToolBarFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topAnchorID)

                    self.exchangeRateSection()
                    self.packingSection()
                    self.shoppingSection()
                    self.koreanPhraseSection()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
            }
            .onChange(of: self.store.scrollToTopTrigger) { _, _ in
                proxy.scrollTo(Self.topAnchorID, anchor: .top)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.ToolBar.hubTitle)
        }
        .fullScreenCover(item: self.$store.scope(state: \.phraseDetailState, action: \.phraseDetail)) { store in
            KoreanPhraseDetailView(store: store)
        }
        .sheet(item: self.$store.scope(state: \.packingPlanPickerState, action: \.packingPlanPicker)) { store in
            ToolBarPlanPickerView(store: store)
        }
        .sheet(item: self.$store.scope(state: \.shoppingPlanPickerState, action: \.shoppingPlanPicker)) { store in
            ShoppingPlanPickerView(store: store)
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
                            Button {
                                self.store.send(.packingPreviewRowTapped(item))
                            } label: {
                                self.packingPreviewRow(item)
                            }
                            .buttonStyle(TabiPressStyle())
                        }
                    }
                }
            }

            if self.store.hasPackingLoadFailed == false {
                self.sectionMoreButton {
                    self.store.send(.packingListButtonTapped)
                }
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
                            Button {
                                self.store.send(.phrasePreviewRowTapped(phrase))
                            } label: {
                                self.phrasePreviewRow(phrase)
                            }
                            .buttonStyle(TabiPressStyle())
                            // 기본 탭 동작(가로모드 상세 진입)은 그대로 유지하고, 롱프레스 시에만 복사/크게보기 메뉴를 노출한다
                            .contextMenu {
                                Button(Strings.KoreanPhrase.copyMenuTitle, systemImage: "doc.on.doc") {
                                    self.store.send(.phraseCopyMenuTapped(phrase))
                                }
                                Button(Strings.KoreanPhrase.viewLargeMenuTitle, systemImage: "arrow.up.left.and.arrow.down.right") {
                                    self.store.send(.phrasePreviewRowTapped(phrase))
                                }
                            }
                        }
                    }
                }
            }

            if self.store.hasPhraseLoadFailed == false {
                self.sectionMoreButton {
                    self.store.send(.koreanPhraseListButtonTapped)
                }
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

// MARK: - Shopping Section

private extension ToolBarView {
    @ViewBuilder
    func shoppingSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TabiLabel(title: Strings.Shopping.sectionTitle, style: .titleM, color: .tabiTextPrimary)

            if self.store.isLoadingShopping {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if self.store.hasShoppingLoadFailed {
                TabiRetryableEmptyState(description: Strings.Shopping.loadFailedDescription) {
                    self.store.send(.shoppingRetryButtonTapped)
                }
            } else if self.store.shoppingItems.isEmpty {
                TabiEmptyState(
                    systemImageName: "bag",
                    title: Strings.Shopping.emptyTitle,
                    description: Strings.Shopping.emptyDescription,
                    style: .card
                )
            } else {
                TabiCard {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(self.store.shoppingPreviewItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                            Button {
                                self.store.send(.shoppingPreviewRowTapped(item))
                            } label: {
                                self.shoppingPreviewRow(item)
                            }
                            .buttonStyle(TabiPressStyle())
                        }
                    }
                }
            }

            if self.store.hasShoppingLoadFailed == false {
                self.sectionMoreButton {
                    self.store.send(.shoppingListButtonTapped)
                }
            }
        }
    }

    func shoppingPreviewRow(_ item: ShoppingItem) -> some View {
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

    let mockShoppingItemUseCase: TestShoppingItemUseCase = {
        let useCase = TestShoppingItemUseCase()
        useCase.recommendedItems = [
            ShoppingItem(id: "ginseng", order: 0, title: "高麗人参", note: "お土産の定番"),
            ShoppingItem(id: "cosmetics", order: 1, title: "韓国コスメ", note: nil)
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
                dependency.shoppingItemUseCase = mockShoppingItemUseCase
            }
        )
    )
}
