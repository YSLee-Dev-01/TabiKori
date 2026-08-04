//
//  AddToItineraryDayRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 펼쳐진 일정 하위에 표시되는 날짜 행
struct AddToItineraryDayRow: View {
    let dayTitle: String
    let dateTitle: String
    let onTapped: () -> Void

    var body: some View {
        Button {
            self.onTapped()
        } label: {
            HStack(spacing: 8) {
                TabiLabel(title: self.dayTitle, style: .bodySBold, color: .tabiTextPrimary)
                TabiLabel(title: self.dateTitle, style: .captionM, color: .tabiTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(TabiColor.tabiTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(TabiColor.tabiSurface)
            .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
        }
        .buttonStyle(TabiPressStyle())
    }
}
