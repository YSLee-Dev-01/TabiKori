//
//  AddCustomPlaceView.swift
//  Presentation
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct AddCustomPlaceView: View {

    @Bindable private var store: StoreOf<AddCustomPlaceFeature>

    public init(store: StoreOf<AddCustomPlaceFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.categorySection()
                self.titleField()
                self.addressField()
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.AddCustomPlace.screenTitle) {
                self.closeButton()
            }
            .padding(.top, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AddCustomPlaceBottomCTAView(isEnabled: self.store.isConfirmEnabled, isLoading: self.store.isSaving) {
                self.store.send(.confirmTapped)
            }
        }
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - View

private extension AddCustomPlaceView {
    func closeButton() -> some View {
        Button {
            self.store.send(.closeTapped)
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(TabiColor.tabiTextSecondary)
                .frame(width: 32, height: 32)
                .background(TabiColor.tabiSurface)
                .clipShape(Circle())
        }
        .buttonStyle(TabiPressStyle())
    }

    func categorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Common.categoryTitle, style: .bodyMBold, color: .tabiTextPrimary)
            BookmarkCategoryFilterBar(selectedCategory: self.store.selectedCategory, includesAllChip: false) { category in
                guard let category else { return }
                self.store.send(.categorySelected(category))
            }
        }
    }

    func titleField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.AddCustomPlace.titleLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.AddCustomPlace.titlePlaceholder, text: self.$store.title)
        }
    }

    func addressField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.AddCustomPlace.addressLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.AddCustomPlace.addressPlaceholder, text: self.$store.address)
        }
    }
}
