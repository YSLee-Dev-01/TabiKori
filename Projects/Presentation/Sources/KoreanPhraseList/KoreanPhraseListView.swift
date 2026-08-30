//
//  KoreanPhraseListView.swift
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

public struct KoreanPhraseListView: View {

    @Bindable private var store: StoreOf<KoreanPhraseListFeature>

    public init(store: StoreOf<KoreanPhraseListFeature>) {
        self.store = store
    }

    public var body: some View {
        self.content()
            .navigationTitle(Strings.KoreanPhrase.listTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                    .accessibilityLabel(Strings.KoreanPhrase.addButtonAccessibilityLabel)
                }
            }
            .sheet(item: self.$store.scope(state: \.addPhraseState, action: \.addPhrase)) { store in
                AddKoreanPhraseView(store: store)
            }
            .fullScreenCover(item: self.$store.scope(state: \.phraseDetailState, action: \.phraseDetail)) { store in
                KoreanPhraseDetailView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension KoreanPhraseListView {
    var showsSectionHeaders: Bool {
        self.store.customPhrases.isEmpty == false
    }

    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed && self.store.customPhrases.isEmpty {
            TabiRetryableEmptyState(description: Strings.KoreanPhrase.loadFailedDescription) {
                self.store.send(.retryButtonTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed == false && self.store.phrases.isEmpty && self.store.customPhrases.isEmpty {
            TabiEmptyState(
                systemImageName: "text.bubble",
                title: Strings.KoreanPhrase.emptyTitle,
                description: Strings.KoreanPhrase.emptyDescription,
                style: .card
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self.list()
        }
    }

    func list() -> some View {
        List {
            if self.store.customPhrases.isEmpty == false {
                Section {
                    ForEach(self.store.customPhrases) { phrase in
                        KoreanPhraseRow(
                            phrase: phrase,
                            onTap: { self.store.send(.phraseRowTapped(phrase)) },
                            onCopyTapped: { self.store.send(.phraseCopyMenuTapped(phrase)) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                self.store.send(.customPhraseDeleted(id: phrase.id))
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                            .tint(Color.getTabiColor(.tabiPrimary))
                        }
                    }
                } header: {
                    self.sectionHeader(title: Strings.KoreanPhrase.customSectionHeader)
                }
            }

            Section {
                if self.store.hasLoadFailed {
                    TabiRetryableEmptyState(description: Strings.KoreanPhrase.loadFailedDescription) {
                        self.store.send(.retryButtonTapped)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else if self.store.phrases.isEmpty {
                    TabiLabel(title: Strings.KoreanPhrase.emptyDescription, style: .bodyM, color: .tabiTextSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(self.store.phrases) { phrase in
                        KoreanPhraseRow(
                            phrase: phrase,
                            onTap: { self.store.send(.phraseRowTapped(phrase)) },
                            onCopyTapped: { self.store.send(.phraseCopyMenuTapped(phrase)) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                }
            } header: {
                if self.showsSectionHeaders {
                    self.sectionHeader(title: Strings.KoreanPhrase.defaultSectionHeader)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func sectionHeader(title: String) -> some View {
        TabiLabel(title: title, style: .captionMBold, color: .tabiTextSecondary)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // List Section 헤더는 .plain 스타일에서도 자체 기본 inset을 추가로 적용해 row(listRowInsets leading 20)보다
            // 더 들어가 보임 — ShoppingPlanListView 헤더와 동일하게 listRowInsets를 0으로 지정해 기본 inset을 제거하고
            // 위 .padding(.horizontal, 20)만으로 실제 좌측 여백을 결정하게 함
            .listRowInsets(EdgeInsets())
    }
}

#Preview {
    let mockUseCase: TestKoreanPhraseUseCase = {
        let useCase = TestKoreanPhraseUseCase()
        useCase.phrases = [
            KoreanPhrase(id: "hello", order: 0, korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ"),
            KoreanPhrase(id: "thanks", order: 1, korean: "감사합니다", japanese: "ありがとうございます", pronunciation: "カムサハムニダ")
        ]
        useCase.customPhrases = [
            KoreanPhrase(id: "custom_1", order: 0, korean: "화이팅", japanese: "ファイティン", pronunciation: nil, isCustom: true)
        ]
        return useCase
    }()

    NavigationStack {
        KoreanPhraseListView(
            store: Store(
                initialState: KoreanPhraseListFeature.State(),
                reducer: { KoreanPhraseListFeature() },
                withDependencies: { dependency in
                    dependency.koreanPhraseUseCase = mockUseCase
                }
            )
        )
    }
}
