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
                self.dateBox(label: Strings.Festival.startDateLabel, date: self.startDate, field: .start)
                self.dateBox(label: Strings.Festival.endDateLabel, date: self.endDate, field: .end)
            }

            if self.endDate != nil {
                TabiLabel(
                    title: Strings.Festival.dateRangeFilterNotice,
                    style: .captionM,
                    color: .tabiTextTertiary,
                    isExpanded: true
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let activeField {
                TabiRangeCalendar(
                    startDate: self.$startDate,
                    endDate: self.validatedEndDate,
                    initialMonth: self.initialMonth(for: activeField),
                    editingField: self.calendarField(for: activeField)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.tabiStandard, value: self.endDate)
    }
}

// MARK: - View

private extension FestivalDateRangeView {
    func dateBox(label: String, date: Date?, field: FestivalDateField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                TabiLabel(title: label, style: .captionM, color: .tabiTextSecondary)

                if field == .end, date != nil {
                    Spacer(minLength: 0)
                    Button {
                        self.endDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
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
    /// 종료일이 시작일보다 이전인 탭은 store에 전달하지 않고 무시한다
    var validatedEndDate: Binding<Date?> {
        Binding(
            get: { self.endDate },
            set: { newValue in
                if let newValue, let startDate = self.startDate, newValue < startDate {
                    return
                }
                self.endDate = newValue
            }
        )
    }

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
