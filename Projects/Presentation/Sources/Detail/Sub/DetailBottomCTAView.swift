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
    let onSaveTapped: () -> Void
    let onAddToItineraryTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                self.onSaveTapped()
            } label: {
                Image(systemName: self.isSaved ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(self.isSaved ? TabiColor.tabiPrimary : TabiColor.tabiTextSecondary)
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
            }
            .buttonStyle(TabiPressStyle())

            TabiButton(
                Strings.Detail.ctaAddToItinerary,
                style: .primary,
                icon: Image(systemName: "plus"),
                isExpanded: true
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
