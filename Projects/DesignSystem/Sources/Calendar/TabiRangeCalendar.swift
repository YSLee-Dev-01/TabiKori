//
//  TabiRangeCalendar.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 월 단위 그리드 + 요일 헤더로 구성된 기간(범위) 선택 캘린더
/// - 선택 규칙: 첫 탭 = 시작일, 두 번째 탭이 시작일 이후면 종료일 확정 / 이전이면 시작일 재설정
///   → 종료일이 시작일보다 빠른 조합은 절대 만들어지지 않음
public struct TabiRangeCalendar: View {

    // MARK: - Properties

    @Binding private var startDate: Date?
    @Binding private var endDate: Date?
    @State private var displayedMonth: Date

    /// 요일 헤더(日 月 火 水 木 金 土)가 항상 일요일 시작으로 고정되어 있으므로,
    /// 날짜 그리드 계산도 기기 로케일의 `firstWeekday`와 무관하게 일요일 기준으로 고정한다
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        return calendar
    }()
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    // MARK: - Init

    public init(
        startDate: Binding<Date?>,
        endDate: Binding<Date?>,
        initialMonth: Date = Date()
    ) {
        self._startDate = startDate
        self._endDate = endDate
        self._displayedMonth = State(initialValue: initialMonth)
    }

    // MARK: - View

    public var body: some View {
        VStack(spacing: 16) {
            self.monthHeader()
            self.weekdayHeader()
            self.dateGrid()
        }
    }
}

// MARK: - View

private extension TabiRangeCalendar {
    func monthHeader() -> some View {
        HStack {
            Button {
                self.moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(TabiColor.tabiTextPrimary)
            }

            Spacer()

            TabiLabel(
                title: self.monthTitle,
                style: .titleS,
                color: .tabiTextPrimary
            )

            Spacer()

            Button {
                self.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(TabiColor.tabiTextPrimary)
            }
        }
    }

    func weekdayHeader() -> some View {
        HStack {
            ForEach(Array(self.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                TabiLabel(
                    title: symbol,
                    style: .captionMBold,
                    color: self.weekdayColor(for: index),
                    alignment: .center,
                    isExpanded: true
                )
            }
        }
    }

    func dateGrid() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(self.daysInDisplayedMonth.enumerated()), id: \.offset) { _, day in
                if let day {
                    self.dayCell(day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    func dayCell(_ day: Date) -> some View {
        Button {
            self.selectDate(day)
        } label: {
            TabiLabel(
                title: "\(self.calendar.component(.day, from: day))",
                style: self.isEndpoint(day) ? .bodyMBold : .bodyM,
                color: self.dayTextColor(day),
                alignment: .center,
                isExpanded: true
            )
            .frame(height: 36)
            .background {
                if self.isEndpoint(day) {
                    Circle().fill(TabiColor.tabiPrimary)
                } else if self.isInRange(day) {
                    Rectangle().fill(TabiColor.tabiPrimaryLight.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Method

private extension TabiRangeCalendar {
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: self.displayedMonth)
    }

    var daysInDisplayedMonth: [Date?] {
        guard
            let monthInterval = self.calendar.dateInterval(of: .month, for: self.displayedMonth),
            let firstWeekday = self.calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }

        let leadingBlanks = (firstWeekday - self.calendar.firstWeekday + 7) % 7
        let daysCount = self.calendar.range(of: .day, in: .month, for: self.displayedMonth)?.count ?? 0

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<daysCount {
            if let date = self.calendar.date(byAdding: .day, value: offset, to: monthInterval.start) {
                days.append(date)
            }
        }
        return days
    }

    func moveMonth(by value: Int) {
        guard let newMonth = self.calendar.date(byAdding: .month, value: value, to: self.displayedMonth) else { return }
        self.displayedMonth = newMonth
    }

    func selectDate(_ date: Date) {
        guard let start = self.startDate, self.endDate == nil else {
            self.startDate = date
            self.endDate = nil
            return
        }

        if date < start {
            self.startDate = date
        } else {
            self.endDate = date
        }
    }

    func isEndpoint(_ day: Date) -> Bool {
        if let start = self.startDate, self.calendar.isDate(day, inSameDayAs: start) { return true }
        if let end = self.endDate, self.calendar.isDate(day, inSameDayAs: end) { return true }
        return false
    }

    func isInRange(_ day: Date) -> Bool {
        guard let start = self.startDate, let end = self.endDate else { return false }
        return day > start && day < end
    }

    func dayTextColor(_ day: Date) -> TabiColor {
        if self.isEndpoint(day) { return .tabiOnColor }
        let weekday = self.calendar.component(.weekday, from: day)
        if weekday == 1 { return .tabiDestructive }
        if weekday == 7 { return .tabiPrimary }
        return .tabiTextPrimary
    }

    func weekdayColor(for symbolIndex: Int) -> TabiColor {
        if symbolIndex == 0 { return .tabiDestructive }
        if symbolIndex == 6 { return .tabiPrimary }
        return .tabiTextSecondary
    }
}
