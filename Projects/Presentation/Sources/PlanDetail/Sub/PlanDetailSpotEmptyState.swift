//
//  PlanDetailSpotEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailSpotEmptyState: View {

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 34))
                .foregroundStyle(TabiColor.tabiTextTertiary)

            VStack(spacing: 3) {
                TabiLabel(title: Strings.Plan.spotEmptyTitle, style: .bodySBold, color: .tabiTextSecondary)
                TabiLabel(
                    title: Strings.Plan.spotEmptyDescription,
                    style: .captionM,
                    color: .tabiTextTertiary,
                    alignment: .center
                )
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .stroke(TabiColor.tabiBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
    }
}
