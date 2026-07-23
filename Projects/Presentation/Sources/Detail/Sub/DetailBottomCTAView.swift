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
        HStack(spacing: 10) {
            Button {
                self.onRouteDirectionsTapped()
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(TabiColor.tabiTextSecondary)
                    .frame(width: 45, height: 45)
                    .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
            }
            .buttonStyle(TabiPressStyle())
            .disabled(self.isRouteDirectionsDisabled)

            TabiButton(
                Strings.Detail.ctaAddToItinerary,
                style: .primary,
                icon: Image(systemName: "plus"),
                isExpanded: true,
                height: 45
            ) {
                self.onAddToItineraryTapped()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
