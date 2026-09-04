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

    @State private var selectedDetent: PresentationDetent = .medium
    @FocusState private var isJapaneseFocused: Bool
    @FocusState private var isKoreanFocused: Bool
    @FocusState private var isPronunciationFocused: Bool

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
            TabiNavigationBar(title: Strings.KoreanPhrase.addFormTitle, titleStyle: .titleS) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaBar(edge: .bottom) {
            self.saveButton()
        }
        .presentationDetents([.medium, .large], selection: self.$selectedDetent)
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .translateSearchTask(
            pendingQuery: self.store.pendingTranslationJapanese,
            onResult: { self.store.send(.translationResultReceived($0)) },
            onFailure: { self.store.send(.translationFailed) }
        )
        // 텍스트필드 포커스 시 시트를 large로 미리 확장해둔다. 키보드가 올라오면서 발생하는 safe area 변화에
        // 따라 시트가 자동으로 detent를 전환하도록 두면, 키보드 애니메이션과 detent 전환 애니메이션이 서로
        // 어긋나며 하단 저장 버튼이 뚝 떨어지듯 움직인다. 포커스 변화를 직접 감지해 selectedDetent를 갱신하면
        // 두 애니메이션이 하나로 합쳐져 자연스럽게 이어진다
        .onChange(of: self.isJapaneseFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isKoreanFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isPronunciationFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
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
            TabiTextField(
                placeholder: Strings.KoreanPhrase.koreanFieldPlaceholder,
                text: self.$store.korean,
                focus: self.$isKoreanFocused
            )
        }
    }

    func japaneseField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.KoreanPhrase.japaneseFieldLabel, style: .bodyMBold, color: .tabiTextPrimary)
            HStack(spacing: 8) {
                TabiTextField(
                    placeholder: Strings.KoreanPhrase.japaneseFieldPlaceholder,
                    text: self.$store.japanese,
                    focus: self.$isJapaneseFocused
                )
                TabiButton(
                    Strings.KoreanPhrase.translateButtonTitle,
                    style: .surface,
                    isLoading: self.store.isTranslating,
                    cornerRadius: .tabiRadiusMd
                ) {
                    self.store.send(.translateButtonTapped)
                }
            }
        }
    }

    func pronunciationField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.KoreanPhrase.pronunciationFieldLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(
                placeholder: Strings.KoreanPhrase.pronunciationFieldPlaceholder,
                text: self.$store.pronunciation,
                focus: self.$isPronunciationFocused
            )
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
