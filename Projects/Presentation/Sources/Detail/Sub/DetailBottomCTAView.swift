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
    let onRouteDirectionsTapped: () -> Void
    let onAddToItineraryTapped: () -> Void
    let isRouteDirectionsDisabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            TabiGlassIconButton(
                systemName: "arrow.triangle.turn.up.right.diamond",
                size: .lg,
                foregroundColor: .tabiTextSecondary
            ) {
                self.onRouteDirectionsTapped()
            }
            .disabled(self.isRouteDirectionsDisabled)

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
