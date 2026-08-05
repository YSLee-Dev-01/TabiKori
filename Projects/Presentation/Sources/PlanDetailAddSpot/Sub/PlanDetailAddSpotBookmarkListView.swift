//
//  PlanDetailAddSpotBookmarkListView.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct PlanDetailAddSpotBookmarkListView: View {
    let bookmarks: [Bookmark]
    let isLoading: Bool
    let onSpotTapped: (TouristSpot) -> Void

    var body: some View {
        List {
            if self.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            } else if self.bookmarks.isEmpty {
                TabiEmptyState(
                    systemImageName: "heart.slash",
                    title: Strings.Bookmark.emptyTitle,
                    description: Strings.Bookmark.emptyDescription
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            } else {
                ForEach(self.bookmarks) { bookmark in
                    PlanDetailAddSpotSpotRow(spot: bookmark.touristSpot) {
                        self.onSpotTapped(bookmark.touristSpot)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
