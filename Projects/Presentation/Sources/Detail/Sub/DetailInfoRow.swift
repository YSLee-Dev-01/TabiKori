//
//  DetailInfoRow.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct DetailInfoRow: View {
    let systemName: String
    let label: String
    let value: String
    let color: TabiColor

    var body: some View {
        TabiCard {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: .tabiRadiusSm)
                    .fill(self.color.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: self.systemName)
                            .font(.system(size: 16))
                            .foregroundStyle(self.color)
                    }
                VStack(alignment: .leading, spacing: 3) {
                    TabiLabel(title: self.label, style: .captionM, color: .tabiTextTertiary)
                    TabiLabel(title: self.value, style: .bodyS, color: .tabiTextPrimary, isExpanded: true)
                }
                Spacer()
            }
            .padding(14)
        }
    }
}
