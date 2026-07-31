//
//  AddPlanDateRangeView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct AddPlanDateRangeView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                self.dateBox(label: Strings.Plan.departureLabel, date: self.startDate)
                self.dateBox(label: Strings.Plan.returnLabel, date: self.endDate)
            }

            TabiRangeCalendar(startDate: self.$startDate, endDate: self.$endDate)
        }
    }
}

// MARK: - View

private extension AddPlanDateRangeView {
    func dateBox(label: String, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiLabel(title: label, style: .captionM, color: .tabiTextSecondary)
            TabiLabel(
                title: date?.planPeriodDateTitle ?? Strings.Plan.datePlaceholder,
                style: .bodyMBold,
                color: .tabiTextPrimary
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TabiColor.tabiSurface)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
        .overlay {
            RoundedRectangle(cornerRadius: .tabiRadiusMd)
                .stroke(TabiColor.tabiBorder, lineWidth: 1)
        }
    }
}
