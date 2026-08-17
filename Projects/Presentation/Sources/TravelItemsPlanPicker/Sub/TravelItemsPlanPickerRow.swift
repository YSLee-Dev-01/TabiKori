//
//  TravelItemsPlanPickerRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

/// 준비물을 저장할 플랜 한 건을 나타내는 행. 날짜 선택 없이 탭 1회로 선택이 끝난다
struct TravelItemsPlanPickerRow: View {
    let plan: TravelPlan
    let onTap: () -> Void

    var body: some View {
        Button {
            self.onTap()
        } label: {
            TabiCard {
                HStack(spacing: 12) {
                    Text(self.plan.displayEmoji)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        TabiLabel(title: self.plan.title, style: .bodyMBold, color: .tabiTextPrimary)
                        TabiLabel(
                            title: "\(self.plan.displayRegionTitle) · \(self.plan.periodTitle)",
                            style: .captionM,
                            color: .tabiTextSecondary
                        )
                    }

                    Spacer()
                }
                .padding(16)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}
