//
//  TabiGlassIconButton.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiGlassIconButton: View {

    public enum Size {
        case sm
        case md
        case lg

        var iconSize: CGFloat {
            switch self {
            case .sm: return 14
            case .md: return 18
            case .lg: return 22
            }
        }

        var padding: CGFloat {
            switch self {
            case .sm: return 8
            case .md: return 10
            case .lg: return 12
            }
        }
    }

    private let systemName: String
    private let size: Size
    private let foregroundColor: TabiColor
    private let action: () -> Void

    public init(
        systemName: String,
        size: Size = .md,
        foregroundColor: TabiColor = .tabiPrimary,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.size = size
        self.foregroundColor = foregroundColor
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            TabiGlassIconLabel(
                systemName: self.systemName,
                size: self.size,
                foregroundColor: self.foregroundColor
            )
        }
    }
}

/// `Menu` 등 자체적으로 탭 제스처를 처리하는 컨테이너의 label로 쓰기 위한 아이콘 전용 뷰
/// `TabiGlassIconButton`과 동일한 시각 스타일(아이콘 크기/패딩/글래스 효과)을 공유한다
public struct TabiGlassIconLabel: View {
    private let systemName: String
    private let size: TabiGlassIconButton.Size
    private let foregroundColor: TabiColor

    public init(
        systemName: String,
        size: TabiGlassIconButton.Size = .md,
        foregroundColor: TabiColor = .tabiPrimary
    ) {
        self.systemName = systemName
        self.size = size
        self.foregroundColor = foregroundColor
    }

    public var body: some View {
        Image(systemName: self.systemName)
            .resizable()
            .frame(width: self.size.iconSize, height: self.size.iconSize)
            .padding(self.size.padding)
            .foregroundStyle(Color.getTabiColor(self.foregroundColor))
            .glassEffect(.regular, in: .circle)
    }
}
