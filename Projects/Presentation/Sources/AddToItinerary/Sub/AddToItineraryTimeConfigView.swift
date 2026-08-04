//
//  AddToItineraryTimeConfigView.swift
//  Presentation
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// Step 2 — 선택한 일정/날짜 요약 + 시작·종료 시각 입력 + 저장 버튼
struct AddToItineraryTimeConfigView: View {
    let planTitle: String
    let dayTitle: String
    let dateTitle: String
    @Binding var startTime: Date
    @Binding var endTime: Date
    let durationMinutes: Int
    let isSaveEnabled: Bool
    let isSaving: Bool
    let onSaveTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                self.selectionSummary()
                AddToItineraryTimeForm(
                    startTime: self.$startTime,
                    endTime: self.$endTime,
                    durationMinutes: self.durationMinutes
                )
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            self.saveButton()
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Method

private extension AddToItineraryTimeConfigView {
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
