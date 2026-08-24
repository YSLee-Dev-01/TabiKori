//
//  PlanDetailTimeEditView.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// PlanDetail 편집모드 스팟 행 탭 시 여는 시간 수정 바텀시트
struct PlanDetailTimeEditView: View {
    @Bindable private var store: StoreOf<PlanDetailTimeEditFeature>

    init(store: StoreOf<PlanDetailTimeEditFeature>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            self.header()
            TabiItineraryTimeConfigView(
                planTitle: self.store.planTitle,
                dayTitle: self.store.dayTitle,
                dateTitle: self.store.dateTitle,
                startTime: self.$store.startTime,
                endTime: self.$store.endTime,
                durationMinutes: self.store.durationMinutes,
                isTimeUnset: self.$store.isTimeUnset,
                isSaveEnabled: self.store.isSaveEnabled,
                isSaving: self.store.isSaving,
                onSaveTapped: { self.store.send(.saveButtonTapped) }
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - View

private extension PlanDetailTimeEditView {
    func header() -> some View {
        HStack(spacing: 12) {
            TabiLabel(title: Strings.Plan.timeEditSheetTitle, style: .titleS, color: .tabiTextPrimary)
            Spacer()
            Button {
                self.store.send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(TabiColor.tabiTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(TabiColor.tabiSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(TabiPressStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }
}

#Preview {
    PlanDetailTimeEditView(
        store: Store(
            initialState: PlanDetailTimeEditFeature.State(
                planId: TravelPlan.mock.id,
                planTitle: TravelPlan.mock.title,
                dayTitle: "1日目",
                dateTitle: Date().planDayHeaderTitle,
                spot: TravelPlanDetail.mock.spots[0]
            ),
            reducer: { PlanDetailTimeEditFeature() }
        )
    )
}
