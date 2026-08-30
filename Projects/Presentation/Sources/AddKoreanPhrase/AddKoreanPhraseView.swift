//
//  AddKoreanPhraseView.swift
//  Presentation
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct AddKoreanPhraseView: View {

    @Bindable private var store: StoreOf<AddKoreanPhraseFeature>

    public init(store: StoreOf<AddKoreanPhraseFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.japaneseField()
                self.koreanField()
                self.pronunciationField()
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.KoreanPhrase.addFormTitle) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaBar(edge: .bottom) {
            self.saveButton()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .translateSearchTask(
            pendingQuery: self.store.pendingTranslationJapanese,
            onResult: { self.store.send(.translationResultReceived($0)) },
            onFailure: { self.store.send(.translationFailed) }
        )
    }
}

// MARK: - View

private extension AddKoreanPhraseView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeTapped)
        }
    }

    func saveButton() -> some View {
        TabiButton(
            Strings.KoreanPhrase.saveButtonTitle,
            style: .primary,
            isExpanded: true,
            isLoading: self.store.isSaving,
            height: 45,
            cornerRadius: .tabiRadiusFull
        ) {
            self.store.send(.saveButtonTapped)
        }
        .disabled(!self.store.isSaveEnabled)
        .padding(.horizontal, 20)
    }

    func koreanField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.KoreanPhrase.koreanFieldLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.KoreanPhrase.koreanFieldPlaceholder, text: self.$store.korean)
        }
    }

    func japaneseField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.KoreanPhrase.japaneseFieldLabel, style: .bodyMBold, color: .tabiTextPrimary)
            HStack(spacing: 8) {
                TabiTextField(placeholder: Strings.KoreanPhrase.japaneseFieldPlaceholder, text: self.$store.japanese)
                TabiButton(
                    Strings.KoreanPhrase.translateButtonTitle,
                    style: .ghost,
                    isLoading: self.store.isTranslating
                ) {
                    self.store.send(.translateButtonTapped)
                }
            }
        }
    }

    func pronunciationField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.KoreanPhrase.pronunciationFieldLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.KoreanPhrase.pronunciationFieldPlaceholder, text: self.$store.pronunciation)
        }
    }
}

#Preview {
    AddKoreanPhraseView(
        store: Store(
            initialState: AddKoreanPhraseFeature.State(),
            reducer: { AddKoreanPhraseFeature() },
            withDependencies: { dependency in
                dependency.koreanPhraseUseCase = TestKoreanPhraseUseCase()
            }
        )
    )
}
