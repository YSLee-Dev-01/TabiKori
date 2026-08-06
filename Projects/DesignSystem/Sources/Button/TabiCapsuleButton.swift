//
//  TabiCapsuleButton.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiCapsuleButton: View {

    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            HStack(spacing: 6) {
                Image(systemName: self.systemImage)
                TabiLabel(title: self.title, style: .bodyMBold, color: .tabiOnColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(TabiColor.tabiPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(TabiPressStyle())
    }
}
