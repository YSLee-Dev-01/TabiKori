//
//  AddCustomPlaceBottomCTAView.swift
//  Presentation
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct AddCustomPlaceBottomCTAView: View {
    let isEnabled: Bool
    let isLoading: Bool
    let onConfirmTapped: () -> Void

    var body: some View {
        TabiButton(
            Strings.AddCustomPlace.saveButton,
            style: .primary,
            isExpanded: true,
            isLoading: self.isLoading,
            height: 45,
            cornerRadius: .tabiRadiusFull
        ) {
            self.onConfirmTapped()
        }
        .disabled(!self.isEnabled)
        .padding(.horizontal, 20)
    }
}
