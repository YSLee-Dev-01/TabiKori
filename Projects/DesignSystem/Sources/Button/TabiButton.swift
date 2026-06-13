//
//  TabiButton.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiButton: View {

    public enum Style {
        case primary
        case secondary
        case ghost
    }

    private let title: String
    private let style: Style
    private let icon: Image?
    private let isExpanded: Bool
    private let isLoading: Bool
    private let action: () -> Void

    private var foregroundColor: TabiColor {
        switch self.style {
        case .primary: return .tabiOnColor
        case .secondary: return .tabiPrimary
        case .ghost: return .tabiTextPrimary
        }
    }

    private var backgroundColor: TabiColor? {
        switch self.style {
        case .primary: return .tabiPrimary
        case .secondary, .ghost: return nil
        }
    }

    private var horizontalPadding: CGFloat {
        switch self.style {
        case .primary, .secondary: return 20
        case .ghost: return 16
        }
    }

    private var typographyStyle: TypographyStyle {
        switch self.style {
        case .primary, .secondary: return .bodyMBold
        case .ghost: return .bodyM
        }
    }

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: String,
        style: Style,
        icon: Image? = nil,
        isExpanded: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isExpanded = isExpanded
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            HStack(spacing: 8) {
                if self.isLoading {
                    ProgressView()
                        .tint(self.foregroundColor)
                        .transition(.opacity)
                } else {
                    Group {
                        if let icon = self.icon {
                            icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(self.foregroundColor)
                        }
                        TabiLabel(
                            title: self.title,
                            style: self.typographyStyle,
                            color: self.foregroundColor
                        )
                    }
                    .transition(.opacity)
                }
            }
            .animation(.tabiStandard, value: self.isLoading)
            .padding(.vertical, 12)
            .padding(.horizontal, self.horizontalPadding)
            .frame(maxWidth: self.isExpanded ? .infinity : nil)
            .background(self.backgroundColor ?? .tabiBackground)
            .clipShape(.rect(cornerRadius: .tabiRadiusSm))
            .overlay {
                if self.style == .secondary {
                    RoundedRectangle(cornerRadius: .tabiRadiusSm)
                        .stroke(TabiColor.tabiPrimary, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(TabiPressStyle())
        .disabled(self.isLoading)
        .opacity(!self.isEnabled && !self.isLoading ? 0.5 : 1)
    }
}

// MARK: - _TabiPressStyle

private struct TabiPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .animation(.tabiFast, value: configuration.isPressed)
    }
}
