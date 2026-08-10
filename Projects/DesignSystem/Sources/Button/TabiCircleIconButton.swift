//
//  TabiCircleIconButton.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiCircleIconButton: View {

    private let systemName: String
    private let foregroundColor: TabiColor
    private let action: () -> Void

    public init(
        systemName: String,
        foregroundColor: TabiColor = .tabiTextSecondary,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.foregroundColor = foregroundColor
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            Image(systemName: self.systemName)
                .foregroundStyle(self.foregroundColor)
                .frame(width: 32, height: 32)
                .background(TabiColor.tabiSurface)
                .clipShape(Circle())
        }
        .buttonStyle(TabiPressStyle())
    }
}
