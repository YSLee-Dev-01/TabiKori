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
    let onSubmit: () -> Void
    let onSpotTapped: (TouristSpot) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section {
                self.content()
            } header: {
                TabiSearchField(
                    placeholder: Strings.Map.searchPlaceholder,
                    text: self.$keyword,
                    focus: self.$isFocused,
                    onSubmit: self.onSubmit
                )
                .padding(.bottom, 8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - View

private extension PlanDetailAddSpotSearchListView {
    @ViewBuilder
    func content() -> some View {
        if self.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        } else if self.hasSearched == false {
            TabiEmptyState(
                systemImageName: "magnifyingglass",
                description: Strings.Map.searchEmptyDescription
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        } else if self.results.isEmpty {
            TabiEmptyState(
                systemImageName: "mappin.slash",
                title: Strings.Map.searchResultEmptyTitle,
                description: Strings.Map.searchResultEmptyDescription
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        } else {
            ForEach(self.results) { spot in
                PlanDetailAddSpotSpotRow(spot: spot) {
                    self.onSpotTapped(spot)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
}
