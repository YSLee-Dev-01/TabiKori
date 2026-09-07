//
//  TabiEmptyState.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 아이콘 + (선택)제목 + 설명으로 구성된 공용 빈 상태 뷰
/// - `fill`: 사용 가능한 공간을 Spacer로 채워 중앙 정렬 (검색 안내, 결과 없음 등 전체 화면형)
/// - `card`: 점선 테두리 카드형, 리스트 행 등 인라인 배치에 사용
public struct TabiEmptyState: View {

    // MARK: - Properties

    public enum Style {
        case fill
        case card
    }

    private let systemImageName: String
    private let title: String?
    private let description: String
    private let style: Style

    // MARK: - Init

    public init(
        systemImageName: String,
        title: String? = nil,
        description: String,
        style: Style = .fill
    ) {
        self.systemImageName = systemImageName
        self.title = title
        self.description = description
        self.style = style
    }

    // MARK: - View

    public var body: some View {
        switch self.style {
        case .fill:
            self.fillContent()

        case .card:
            self.cardContent()
        }
    }
}

// MARK: - View

private extension TabiEmptyState {
    func fillContent() -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            self.content(descriptionStyle: self.title == nil ? .bodyS : .captionM)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    func cardContent() -> some View {
        self.content(descriptionStyle: .captionM)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusLg)
                    .stroke(TabiColor.tabiBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
    }

    func content(descriptionStyle: TypographyStyle) -> some View {
        VStack(spacing: 10) {
            Image(systemName: self.systemImageName)
                .font(.system(size: 34))
                .foregroundStyle(TabiColor.tabiTextTertiary)

            if let title {
                VStack(spacing: 3) {
                    TabiLabel(title: title, style: .bodySBold, color: .tabiTextSecondary)
                    TabiLabel(title: self.description, style: descriptionStyle, color: .tabiTextTertiary, alignment: .center)
                }
            } else {
                TabiLabel(title: self.description, style: descriptionStyle, color: .tabiTextTertiary, alignment: .center)
            }
        }
    }
}
