//
//  AddPlanBottomCTAView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct AddPlanBottomCTAView: View {
    let isEnabled: Bool
    let onConfirmTapped: () -> Void

    var body: some View {
        TabiButton(
            Strings.Plan.confirmButton,
            style: .primary,
            isExpanded: true,
            height: 45
        ) {
            self.onConfirmTapped()
        }
        .disabled(!self.isEnabled)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
