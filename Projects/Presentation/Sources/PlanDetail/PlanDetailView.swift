//
//  PlanDetailView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// 일정 상세 화면. NavigationBar와 일자 선택 탭을 표시한다. 선택된 날짜의 일정(스팟 목록) View는 이후 별도 기능에서 구현한다
public struct PlanDetailView: View {

    private let store: StoreOf<PlanDetailFeature>

    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if let plan = self.store.plan {
                VStack(alignment: .leading, spacing: 0) {
                    self.navigationBar(plan: plan)
                    self.dayTabScroll(plan: plan)
                    Spacer()
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension PlanDetailView {
    func navigationBar(plan: TravelPlan) -> some View {
        TabiNavigationBar(
            subtitle: "\(plan.displayRegionTitle) · \(Strings.Plan.durationBadge(plan.dayCount))",
            title: plan.title
        )
        .padding(.top, 20)
    }

    func dayTabScroll(plan: TravelPlan) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(plan.dayDates.enumerated()), id: \.offset) { offset, date in
                    PlanDetailDayButton(
                        dayTitle: Strings.Plan.dayChipTitle(offset + 1),
                        dateTitle: date.planDayDateTitle,
                        isSelected: self.store.selectedDayIndex == offset
                    ) {
                        self.store.send(.dayButtonTapped(index: offset))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 20)
    }
}
