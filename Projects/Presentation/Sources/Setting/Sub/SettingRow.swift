//
//  SettingRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct SettingRow: View {
    private let title: String
    private let description: String?
    private let value: String?
    private let isDisabled: Bool
    private let onTap: (() -> Void)?

    init(
        title: String,
        description: String? = nil,
        value: String? = nil,
        isDisabled: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.value = value
        self.isDisabled = isDisabled
        self.onTap = onTap
    }

    var body: some View {
        Button {
            self.onTap?()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    TabiLabel(
                        title: self.title,
                        style: .bodyM,
                        color: self.isDisabled ? .tabiTextTertiary : .tabiTextPrimary
                    )

                    if let description = self.description {
                        TabiLabel(title: description, style: .captionM, color: .tabiTextTertiary)
                    }
                }

                Spacer()

                if let value = self.value {
                    TabiLabel(title: value, style: .bodyS, color: .tabiTextTertiary)
                }

                if self.onTap != nil, self.isDisabled == false {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TabiColor.tabiTextTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabiPressStyle())
        .disabled(self.isDisabled || self.onTap == nil)
    }
}
