//
//  FestivalDateRangeView.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct FestivalDateRangeView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var isEndDateUnlimited: Bool

    var body: some View {
        VStack(spacing: 16) {
            TabiLabel(title: Strings.Festival.periodSectionTitle, style: .titleS, color: .tabiTextPrimary)

            HStack(spacing: 12) {
                self.dateBox(label: Strings.Plan.departureLabel, date: self.startDate)
                self.dateBox(
                    label: Strings.Plan.returnLabel,
                    date: self.isEndDateUnlimited ? nil : self.endDate
                )
            }

            Toggle(Strings.Festival.unlimitedEndDateToggleTitle, isOn: self.$isEndDateUnlimited)

            TabiRangeCalendar(startDate: self.$startDate, endDate: self.$endDate)
                .disabled(self.isEndDateUnlimited)
                .opacity(self.isEndDateUnlimited ? 0.4 : 1)
        }
    }
}

// MARK: - View

private extension FestivalDateRangeView {
    func dateBox(label: String, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiLabel(title: label, style: .captionM, color: .tabiTextSecondary)
            TabiLabel(
                title: date?.festivalPeriodDateTitle ?? Strings.Plan.datePlaceholder,
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
