//
//  TabiTextField.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

public struct TabiTextField: View {

    // MARK: - Properties

    private let placeholder: String
    private let text: Binding<String>
    private let maxLength: Int?

    // MARK: - Init

    public init(
        placeholder: String,
        text: Binding<String>,
        maxLength: Int? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.maxLength = maxLength
    }

    // MARK: - View

    public var body: some View {
        TextField(self.placeholder, text: self.text)
            .font(.pretendard(TypographyStyle.bodyM.weight, size: TypographyStyle.bodyM.size))
            .foregroundStyle(TabiColor.tabiTextPrimary)
            .onChange(of: self.text.wrappedValue) { _, newValue in
                if let maxLength = self.maxLength, newValue.count > maxLength {
                    self.text.wrappedValue = String(newValue.prefix(maxLength))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
            .overlay {
                RoundedRectangle(cornerRadius: .tabiRadiusMd)
                    .stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
    }
}
