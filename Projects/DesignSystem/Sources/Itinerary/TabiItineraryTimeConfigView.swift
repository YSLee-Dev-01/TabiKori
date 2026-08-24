//
//  TabiItineraryTimeConfigView.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// Step 2 — 선택한 일정/날짜 요약 + 시작·종료 시각 입력 + 저장 버튼
public struct TabiItineraryTimeConfigView: View {
    let planTitle: String
    let dayTitle: String
    let dateTitle: String
    @Binding var startTime: Date
    @Binding var endTime: Date
    let durationMinutes: Int
    @Binding var isTimeUnset: Bool
    let isSaveEnabled: Bool
    let isSaving: Bool
    let onSaveTapped: () -> Void

    public init(
        planTitle: String,
        dayTitle: String,
        dateTitle: String,
        startTime: Binding<Date>,
        endTime: Binding<Date>,
        durationMinutes: Int,
        isTimeUnset: Binding<Bool>,
        isSaveEnabled: Bool,
        isSaving: Bool,
        onSaveTapped: @escaping () -> Void
    ) {
        self.planTitle = planTitle
        self.dayTitle = dayTitle
        self.dateTitle = dateTitle
        self._startTime = startTime
        self._endTime = endTime
        self.durationMinutes = durationMinutes
        self._isTimeUnset = isTimeUnset
        self.isSaveEnabled = isSaveEnabled
        self.isSaving = isSaving
        self.onSaveTapped = onSaveTapped
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                self.selectionSummary()
                TabiItineraryTimeForm(
                    startTime: self.$startTime,
                    endTime: self.$endTime,
                    durationMinutes: self.durationMinutes,
                    isTimeUnset: self.$isTimeUnset
                )
            }
            .padding(20)
        }
        .safeAreaBar(edge: .bottom) {
            self.saveButton()
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Method

private extension TabiItineraryTimeConfigView {
    func selectionSummary() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiLabel(title: self.planTitle, style: .bodyMBold, color: .tabiTextPrimary)
            TabiLabel(title: "\(self.dayTitle) · \(self.dateTitle)", style: .captionM, color: .tabiTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func saveButton() -> some View {
        TabiButton(
            Strings.AddToItinerary.saveButton,
            style: .primary,
            isExpanded: true,
            isLoading: self.isSaving,
            height: 50,
            cornerRadius: .tabiRadiusFull
        ) {
            self.onSaveTapped()
        }
        .disabled(self.isSaveEnabled == false)
    }
}
