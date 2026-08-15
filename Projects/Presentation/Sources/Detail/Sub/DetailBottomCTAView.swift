//
//  DetailBottomCTAView.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct DetailBottomCTAView: View {
    let isSaved: Bool
    let isSaveDisabled: Bool
    let onSaveTapped: () -> Void
    let onAddToItineraryTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TabiGlassIconButton(
                systemName: self.isSaved ? "heart.fill" : "heart",
                size: .lg,
                foregroundColor: .tabiPrimary
            ) {
                self.onSaveTapped()
            }
            .disabled(self.isSaveDisabled)

            TabiButton(
                Strings.Detail.ctaAddToItinerary,
                style: .primary,
                icon: Image(systemName: "plus"),
                isExpanded: true,
                height: 45,
                cornerRadius: .tabiRadiusFull
            ) {
                self.onAddToItineraryTapped()
            }
        }
        .padding(.horizontal, 20)
    }
}
