//
//  DetailPinnedTopBar.swift
//  Presentation
//
//  Created by 이윤수 on 7/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem

struct DetailPinnedTopBar: View {
    let isSaved: Bool
    let onBackTapped: () -> Void
    let onShareTapped: () -> Void
    let onSaveTapped: () -> Void

    @Environment(\.safeAreaInsets) private var safeAreaInsets

    var body: some View {
        HStack {
            self.backButton()
            Spacer()
            HStack(spacing: 8) {
                TabiGlassIconButton(systemName: "square.and.arrow.up") {
                    self.onShareTapped()
                }
                TabiGlassIconButton(systemName: self.isSaved ? "heart.fill" : "heart") {
                    self.onSaveTapped()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, self.safeAreaInsets.top + 8)
    }
}

// MARK: - View

private extension DetailPinnedTopBar {
    func backButton() -> some View {
        Button(action: self.onBackTapped) {
            Image(systemName: "chevron.left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .padding(10)
                .foregroundStyle(Color.getTabiColor(.tabiPrimary))
                .glassEffect()
                .overlay(
                    Color.getTabiColor(.tabiPrimary)
                        .opacity(0.1)
                        .clipShape(.circle)
                )
        }
    }
}
