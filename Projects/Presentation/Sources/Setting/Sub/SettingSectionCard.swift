//
//  SettingSectionCard.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct SettingSectionCard<Content: View>: View {
    private let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TabiLabel(title: self.title, style: .captionMBold, color: .tabiTextTertiary)
                .padding(.horizontal, 4)

            TabiCard {
                VStack(spacing: 0) {
                    self.content
                }
            }
        }
    }
}
