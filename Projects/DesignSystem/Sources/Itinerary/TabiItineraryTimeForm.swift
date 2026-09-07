//
//  TabiItineraryTimeForm.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// Step 2 — 시작/종료 시각 입력 폼. 계산된 소요시간을 함께 표시한다.
/// "시간 저장 안 함" 토글이 켜지면 시간 입력 영역을 비활성화한다
struct TabiItineraryTimeForm: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    let durationMinutes: Int
    @Binding var isTimeUnset: Bool

    var body: some View {
        TabiCard {
            VStack(spacing: 16) {
                self.noTimeToggleRow()

                Group {
                    Divider()
                    self.timeRow(title: Strings.AddToItinerary.startTimeLabel, selection: self.$startTime)
                    Divider()
                    self.timeRow(title: Strings.AddToItinerary.endTimeLabel, selection: self.$endTime)
                    Divider()
                    HStack {
                        TabiLabel(title: Strings.AddToItinerary.durationLabel, style: .bodyM, color: .tabiTextSecondary)
                        Spacer()
                        TabiLabel(title: Strings.Plan.spotDurationTitle(self.durationMinutes), style: .bodyMBold, color: .tabiPrimary)
                    }
                }
                .opacity(self.isTimeUnset ? 0.4 : 1)
                .disabled(self.isTimeUnset)
            }
            .padding(16)
        }
    }
}

// MARK: - Method

private extension TabiItineraryTimeForm {
    func noTimeToggleRow() -> some View {
        HStack {
            TabiLabel(title: Strings.AddToItinerary.noTimeToggleTitle, style: .bodyM, color: .tabiTextPrimary)
            Spacer()
            Toggle("", isOn: self.$isTimeUnset)
                .labelsHidden()
                .tint(Color.getTabiColor(.tabiPrimary))
        }
    }

    func timeRow(title: String, selection: Binding<Date>) -> some View {
        HStack {
            TabiLabel(title: title, style: .bodyM, color: .tabiTextPrimary)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }
}
