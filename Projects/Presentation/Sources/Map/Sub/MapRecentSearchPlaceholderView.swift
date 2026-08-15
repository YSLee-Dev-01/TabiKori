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

            VStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 34))
                    .foregroundStyle(TabiColor.tabiTextTertiary)
                TabiLabel(
                    title: Strings.Map.recentSearchPlaceholderDescription,
                    style: .bodyS,
                    color: .tabiTextTertiary,
                    alignment: .center
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, self.keyboardHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
