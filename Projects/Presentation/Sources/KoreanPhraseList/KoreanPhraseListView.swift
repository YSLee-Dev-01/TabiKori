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
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed {
            TabiRetryableEmptyState(description: Strings.KoreanPhrase.loadFailedDescription) {
                self.store.send(.retryButtonTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.phrases.isEmpty {
            TabiEmptyState(
                systemImageName: "text.bubble",
                title: Strings.KoreanPhrase.emptyTitle,
                description: Strings.KoreanPhrase.emptyDescription,
                style: .card
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(self.store.phrases) { phrase in
                    KoreanPhraseRow(
                        phrase: phrase,
                        onTap: {
                            self.store.send(.phraseRowTapped(phrase))
                        },
                        onCopyTapped: {
                            self.store.send(.phraseCopyMenuTapped(phrase))
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    let mockUseCase: TestKoreanPhraseUseCase = {
        let useCase = TestKoreanPhraseUseCase()
        useCase.phrases = [
            KoreanPhrase(id: "hello", order: 0, korean: "안녕하세요", japanese: "こんにちは", pronunciation: "アンニョンハセヨ"),
            KoreanPhrase(id: "thanks", order: 1, korean: "감사합니다", japanese: "ありがとうございます", pronunciation: "カムサハムニダ")
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
