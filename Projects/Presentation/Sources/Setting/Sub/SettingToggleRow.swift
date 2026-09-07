//
//  SettingToggleRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// SettingRow와 동일한 패딩·라벨 스타일을 유지하되, 우측을 Toggle로 대체한 설정 행.
/// 토글 자체가 탭 영역을 제공하므로 SettingRow와 달리 TabiPressStyle Button으로 감싸지 않는다
struct SettingToggleRow: View {
    private let title: String
    private let description: String?
    private let isOn: Binding<Bool>

    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self.isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                TabiLabel(title: self.title, style: .bodyM, color: .tabiTextPrimary)

                if let description = self.description {
                    TabiLabel(title: description, style: .captionM, color: .tabiTextTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: self.isOn)
                .labelsHidden()
                .tint(Color.getTabiColor(.tabiPrimary))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
