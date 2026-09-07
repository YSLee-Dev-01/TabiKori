//
//  MapRecentSearchPlaceholderView.swift
//  Presentation
//
//  Created by 이윤수 on 7/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct MapRecentSearchPlaceholderView: View {
    
    var keyboardHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            TabiEmptyState(
                systemImageName: "clock",
                description: Strings.Map.recentSearchPlaceholderDescription,
                style: .card
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .padding(.bottom, self.keyboardHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
