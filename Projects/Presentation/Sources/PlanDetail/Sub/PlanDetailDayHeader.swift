//
//  PlanDetailDayHeader.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct PlanDetailDayHeader: View {
    let dateTitle: String
    let spotCountTitle: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundStyle(TabiColor.tabiTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                TabiLabel(title: self.dateTitle, style: .bodyMBold, color: .tabiTextPrimary)
                TabiLabel(title: self.spotCountTitle, style: .captionM, color: .tabiTextSecondary)
            }
        }
    }
}
