//
//  TabiToast.swift
//  DesignSystem
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 앱 전역에서 사용하는 Toast 컴포넌트
///
/// DesignSystem은 Domain을 참조하지 않으므로, 상위 레이어(Presentation)에서
/// Domain의 `ToastType`을 `TabiToast.Style`로 변환해 전달한다
public struct TabiToast: View {

    // MARK: - Style

    public enum Style {
        case success
        case info
        case error
    }

    // MARK: - Properties

    private let message: String
    private let style: Style

    // MARK: - Init

    public init(message: String, style: Style) {
        self.message = message
        self.style = style
    }

    // MARK: - View

    public var body: some View {
        HStack(spacing: 10) {
            Image(self.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(self.accentColor)

            TabiLabel(
                title: self.message,
                style: .bodySBold,
                color: .tabiTextPrimary,
                lineLimit: 2
            )

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(TabiColor.tabiSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusLg))
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .stroke(self.accentColor.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
    }
}

// MARK: - Method

private extension TabiToast {
    var icon: TabiIcon {
        switch self.style {
        case .success: return .toastSuccess
        case .info: return .toastInfo
        case .error: return .toastError
        }
    }

    var accentColor: TabiColor {
        switch self.style {
        case .success: return .tabiPrimary
        case .info: return .tabiAccentLavender
        case .error: return .tabiDestructive
        }
    }
}

// MARK: - Modifier

private struct TabiToastModifier: ViewModifier {
    let message: String?
    let style: TabiToast.Style

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = self.message {
                    TabiToast(message: message, style: self.style)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.tabiSpring, value: self.message)
    }
}

public extension View {
    /// 화면 하단에 Toast를 오버레이로 표시한다. `message`가 `nil`이면 표시하지 않는다
    func tabiToast(message: String?, style: TabiToast.Style) -> some View {
        self.modifier(TabiToastModifier(message: message, style: style))
    }
}
