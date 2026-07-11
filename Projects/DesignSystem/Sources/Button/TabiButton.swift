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
        public enum GlassContext {
            case surface
            case accent
            case secondary
        }

        case primary
        case secondary
        case ghost
        case glass(on: GlassContext = .surface)
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
        case .glass(on: .surface): return .tabiPrimary
        case .glass(on: .accent): return .tabiSurface
        case .glass(on: .secondary): return .tabiSecondary
        }
    }

    private var backgroundColor: TabiColor? {
        switch self.style {
        case .primary: return .tabiPrimary
        case .secondary, .ghost, .glass: return nil
        }
    }

    private var horizontalPadding: CGFloat {
        switch self.style {
        case .primary, .secondary, .glass: return 20
        case .ghost: return 16
        }
    }

    private var typographyStyle: TypographyStyle {
        switch self.style {
        case .primary, .secondary, .glass: return .bodyMBold
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
            .modifier(TabiButtonBackground(style: self.style, backgroundColor: self.backgroundColor))
        }
        .buttonStyle(TabiPressStyle())
        .disabled(self.isLoading)
        .opacity(!self.isEnabled && !self.isLoading ? 0.5 : 1)
    }
}

// MARK: - _TabiButtonBackground

private struct TabiButtonBackground: ViewModifier {
    let style: TabiButton.Style
    let backgroundColor: TabiColor?

    func body(content: Content) -> some View {
        switch self.style {
        case .glass(on: .surface), .glass(on: .secondary):
            content
                .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
        case .glass(on: .accent):
            content
                .background(Color.white.opacity(0.25))
                .clipShape(.rect(cornerRadius: .tabiRadiusSm))
                .overlay {
                    RoundedRectangle(cornerRadius: .tabiRadiusSm)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }
        case .secondary:
            content
                .background(self.backgroundColor ?? .tabiBackground)
                .clipShape(.rect(cornerRadius: .tabiRadiusSm))
                .overlay {
                    RoundedRectangle(cornerRadius: .tabiRadiusSm)
                        .stroke(TabiColor.tabiPrimary, lineWidth: 1.5)
                }
        default:
            content
                .background(self.backgroundColor ?? .tabiBackground)
                .clipShape(.rect(cornerRadius: .tabiRadiusSm))
        }
    }
}
