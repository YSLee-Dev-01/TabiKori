//
//  PlanDetailAddSpotSearchListView.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailAddSpotSearchListView: View {
    @Binding var keyword: String
    let results: [TouristSpot]
    let isLoading: Bool
    let hasSearched: Bool
    let focus: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onSpotTapped: (TouristSpot) -> Void

    var body: some View {
        VStack(spacing: 8) {
            TabiSearchField(
                placeholder: Strings.Map.searchPlaceholder,
                text: self.$keyword,
                focus: self.focus,
                onSubmit: self.onSubmit
            )
            .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 0) {
                    self.content()
                }
            }
        }
        .animation(.tabiStandard, value: self.isLoading)
        .animation(.tabiStandard, value: self.hasSearched)
        .animation(.tabiStandard, value: self.results)
    }
}

// MARK: - View

private extension PlanDetailAddSpotSearchListView {
    /// TabiSpotRow는 내부에 16pt 패딩을 갖고 있어, TF/헤더와 동일한 20pt 여백을 맞추려면 4pt만 추가하면 된다
    static let rowHorizontalPadding: CGFloat = 4

    @ViewBuilder
    func content() -> some View {
        if self.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .transition(.opacity)
        } else if self.hasSearched == false {
            TabiEmptyState(
                systemImageName: "magnifyingglass",
                description: Strings.Map.searchEmptyDescription
            )
            .padding(.horizontal, 20)
            .transition(.opacity)
        } else if self.results.isEmpty {
            TabiEmptyState(
                systemImageName: "mappin.slash",
                title: Strings.Map.searchResultEmptyTitle,
                description: Strings.Map.searchResultEmptyDescription
            )
            .padding(.horizontal, 20)
            .transition(.opacity)
        } else {
            ForEach(Array(self.results.enumerated()), id: \.element.id) { index, spot in
                if index > 0 {
                    Divider()
                        .padding(.horizontal, 20)
                }
                PlanDetailAddSpotSpotRow(spot: spot) {
                    self.onSpotTapped(spot)
                }
                .padding(.horizontal, Self.rowHorizontalPadding)
            }
            .transition(.opacity)
        }
    }
}
