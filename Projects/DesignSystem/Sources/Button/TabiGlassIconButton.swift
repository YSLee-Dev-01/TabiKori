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
    private let action: () -> Void

    public init(systemName: String, size: Size = .md, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            Image(systemName: self.systemName)
                .resizable()
                .frame(width: self.size.iconSize, height: self.size.iconSize)
                .padding(self.size.padding)
                .foregroundStyle(Color.getTabiColor(.tabiPrimary))
                .glassEffect()
                .overlay(
                    Color.getTabiColor(.tabiPrimary)
                        .opacity(0.1)
                        .clipShape(.circle)
                )
        }
    }
}
