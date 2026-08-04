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
    var activeField: FestivalDateField?
    var onFieldTapped: (FestivalDateField) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                self.dateBox(label: Strings.Plan.departureLabel, date: self.startDate, field: .start)
                self.dateBox(label: Strings.Plan.returnLabel, date: self.endDate, field: .end)
            }

            if let activeField {
                // 활성 필드 전환 시 캘린더 자체는 유지된 채 표시 월만 이동해야 하므로,
                // transition은 바깥 Group에 걸고 표시 월 재계산용 .id()는 안쪽 TabiRangeCalendar에만 적용
                Group {
                    TabiRangeCalendar(
                        startDate: self.$startDate,
                        endDate: self.$endDate,
                        initialMonth: self.initialMonth(for: activeField),
                        editingField: self.calendarField(for: activeField)
                    )
                    .id(activeField)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - View

private extension FestivalDateRangeView {
    func dateBox(label: String, date: Date?, field: FestivalDateField) -> some View {
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
                .stroke(self.activeField == field ? TabiColor.tabiPrimary : TabiColor.tabiBorder, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.onFieldTapped(field)
        }
    }
}

// MARK: - Method

private extension FestivalDateRangeView {
    func initialMonth(for field: FestivalDateField) -> Date {
        switch field {
        case .start:
            return self.startDate ?? Date()
        case .end:
            return self.endDate ?? self.startDate ?? Date()
        }
    }

    func calendarField(for field: FestivalDateField) -> TabiCalendarField {
        switch field {
        case .start:
            return .start
        case .end:
            return .end
        }
    }
}
