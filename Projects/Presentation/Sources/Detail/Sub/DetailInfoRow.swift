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
    var isLink: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        if let onTap {
            Button(action: onTap) { self.card() }
                .buttonStyle(.tabiPress)
        } else {
            self.card()
        }
    }
}

// MARK: - View

private extension DetailInfoRow {
    func card() -> some View {
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
                    TabiLabel(
                        title: self.value,
                        style: .bodyS,
                        color: self.isLink ? self.color : .tabiTextPrimary,
                        isExpanded: true,
                        isUnderlined: self.isLink
                    )
                    // HStack 끝의 Spacer()와 폭을 다투다 보니 lineLimit(nil)만으로는 줄바꿈이
                    // 확정되지 않고 값이 한 줄로 압축되며 "…"로 잘리는 경우가 있었다.
                    // 세로 방향으로만 고정 크기를 강제해 필요한 줄 수만큼 항상 완전히 펼쳐지도록 한다
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(14)
        }
    }
}
