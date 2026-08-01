//
//  AddTravelPlanView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct AddTravelPlanView: View {

    @Bindable private var store: StoreOf<AddTravelPlanFeature>

    public init(store: StoreOf<AddTravelPlanFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                self.nameField()
                self.regionSection()
                self.emojiField()
                self.dateSection()
            }
            .padding(20)
        }
        .safeAreaBar(edge: .top) {
            TabiNavigationBar(title: Strings.Plan.addScreenTitle) {
                self.closeButton()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AddPlanBottomCTAView(isEnabled: self.store.isConfirmEnabled) {
                self.store.send(.confirmTapped)
            }
        }
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - View

private extension AddTravelPlanView {
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

    func nameField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Plan.nameLabel, style: .bodyMBold, color: .tabiTextPrimary)
            TabiTextField(placeholder: Strings.Plan.namePlaceholder, text: self.$store.title)
        }
    }

    func regionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: Strings.Plan.cityLabel, style: .bodyMBold, color: .tabiTextPrimary)
            AddPlanRegionGridView(
                selectedRegion: self.store.selectedRegion,
                customRegionText: self.$store.customRegionText,
                onSelect: { region in self.store.send(.regionSelected(region)) }
            )
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
            AddPlanDateRangeView(startDate: self.$store.startDate, endDate: self.$store.endDate)
        }
    }
}
