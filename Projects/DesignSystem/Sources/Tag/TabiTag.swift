//
//  TabiTag.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiTag: View {
    private let title: String
    private let color: TabiColor

    public init(
        _ title: String,
        color: TabiColor
    ) {
        self.title = title
        self.color = color
    }

    public var body: some View {
        TabiLabel(
            title: self.title,
            style: .captionXSBold,
            color: self.color
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(self.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
