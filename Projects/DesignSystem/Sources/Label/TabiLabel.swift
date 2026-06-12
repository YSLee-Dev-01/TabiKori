//
//  TabiLabel.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public struct TabiLabel: View {
    private let title: String
    private let style: TypographyStyle
    private let color: Color
    private let alignment: Alignment
    private let isExpanded: Bool
    private let lineLimit: Int?
    
    public init(
        title: String,
        style: TypographyStyle,
        color: Color,
        alignment: Alignment = .leading,
        isExpanded: Bool = false,
        lineLimit: Int? = nil
    ) {
        self.title = title
        self.style = style
        self.color = color
        self.alignment = alignment
        self.isExpanded = isExpanded
        self.lineLimit = lineLimit
    }
    
    public var body: some View {
        Text(self.title)
            .font(.pretendard(self.style.weight, size: self.style.size))
            .foregroundStyle(self.color)
            .lineLimit(self.lineLimit)
            .multilineTextAlignment(self.alignment.textAlignment)
            .frame(maxWidth: self.isExpanded ? .infinity : nil, alignment: self.alignment)
    }
}
