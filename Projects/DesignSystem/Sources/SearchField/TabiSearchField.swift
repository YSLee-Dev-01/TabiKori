//
//  TabiSearchField.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

// MARK: - TabiSearchField

/// 돋보기 아이콘 + placeholder로 구성된 공용 검색 필드
/// - 탭 진입용: `init(placeholder:onTap:)` — 편집 불가, 전체 영역 탭 제스처만 수신 (Home 진입 바 등)
/// - 실제 입력용: `init(placeholder:text:focus:)` — 바인딩된 TextField (Map 검색 모드 등)
public struct TabiSearchField: View {

    /// 배경 스타일
    /// - `solid`: 불투명 surface 배경 (기본)
    /// - `glass`: Liquid Glass 반투명 배경 (지도 등 위에 오버레이 시)
    public enum Style {
        case solid
        case glass
    }

    // MARK: - Properties

    private let placeholder: String
    private let text: Binding<String>?
    private let focus: FocusState<Bool>.Binding?
    private let onTap: (() -> Void)?
    private let style: Style

    // MARK: - Init

    public init(
        placeholder: String,
        style: Style = .solid,
        onTap: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self.text = nil
        self.focus = nil
        self.onTap = onTap
        self.style = style
    }

    public init(
        placeholder: String,
        text: Binding<String>,
        focus: FocusState<Bool>.Binding? = nil,
        style: Style = .solid
    ) {
        self.placeholder = placeholder
        self.text = text
        self.focus = focus
        self.onTap = nil
        self.style = style
    }

    // MARK: - View

    public var body: some View {
        if let text = self.text {
            self.editableField(text)
        } else {
            self.displayField()
        }
    }
}

// MARK: - Method

private extension TabiSearchField {
    @ViewBuilder
    func container<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let base = HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(TabiColor.tabiTextTertiary)

            content()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)

        switch self.style {
        case .solid:
            base
                .background(TabiColor.tabiSurface)
                .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
                .overlay {
                    RoundedRectangle(cornerRadius: .tabiRadiusMd)
                        .stroke(TabiColor.tabiBorder, lineWidth: 1)
                }

        case .glass:
            base
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: .tabiRadiusMd))
        }
    }

    func displayField() -> some View {
        Button {
            self.onTap?()
        } label: {
            self.container {
                TabiLabel(title: self.placeholder, style: .bodyM, color: .tabiTextTertiary)
            }
            .contentShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
        }
        .buttonStyle(TabiPressStyle())
    }

    @ViewBuilder
    func editableField(_ text: Binding<String>) -> some View {
        self.container {
            let field = TextField(self.placeholder, text: text)
                .font(.pretendard(TypographyStyle.bodyM.weight, size: TypographyStyle.bodyM.size))
                .foregroundStyle(TabiColor.tabiTextPrimary)
                .submitLabel(.search)

            if let focus = self.focus {
                field.focused(focus)
            } else {
                field
            }
        }
    }
}
