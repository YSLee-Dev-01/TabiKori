//
//  TabiChip.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button {
            self.action()
        } label: {
            TabiLabel(
                title: self.title,
                style: self.isSelected ? .captionMBold : .captionM,
                color: self.isSelected ? .tabiOnColor : .tabiTextSecondary
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(self.isSelected ? TabiColor.tabiPrimary : TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                if !self.isSelected {
                    Capsule()
                        .stroke(TabiColor.tabiBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.tabiFast, value: self.isSelected)
    }
}
