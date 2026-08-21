//
//  PlanDetailEditView.swift
//  Presentation
//
//  Created by 이윤수 on 8/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

struct PlanDetailEditView: View {

    @Bindable private var store: StoreOf<PlanDetailEditFeature>

    @State private var selectedDetent: PresentationDetent = .medium
    @FocusState private var isTitleFocused: Bool

    init(store: StoreOf<PlanDetailEditFeature>) {
        self.store = store
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.nameField()
                self.emojiField()
                self.dateSection()
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.Plan.editPlanScreenTitle) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaBar(edge: .bottom) {
            TabiButton(
                Strings.Plan.editSaveButton,
                style: .primary,
                isExpanded: true,
                isLoading: self.store.isSaving,
                height: 45,
                cornerRadius: .tabiRadiusFull
            ) {
                self.store.send(.confirmButtonTapped)
            }
            .disabled(!self.store.isConfirmEnabled)
            .padding(.horizontal, 20)
        }
        .presentationDetents([.medium, .large], selection: self.$selectedDetent)
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onChange(of: self.isTitleFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
    }
}

// MARK: - View

private extension PlanDetailEditView {
    func closeButton() -> some View {
        TabiCircleIconButton(systemName: "xmark") {
            self.store.send(.closeButtonTapped)
        }
    }

    func nameField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Plan.nameLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.Plan.namePlaceholder, text: self.$store.title, focus: self.$isTitleFocused)
        }
    }

    func emojiField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Plan.emojiLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.Plan.emojiPlaceholder, text: self.$store.emojiText, maxLength: 1)
        }
    }

    func dateSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Plan.dateLabel, style: .bodyMBold, color: .tabiTextPrimary)
            AddPlanDateRangeView(
                startDate: self.$store.startDate,
                endDate: self.$store.endDate,
                initialMonth: self.store.startDate ?? Date()
            )
        }
    }
}

#Preview {
    PlanDetailEditView(
        store: Store(
            initialState: PlanDetailEditFeature.State(plan: .mock),
            reducer: { PlanDetailEditFeature() }
        )
    )
}
