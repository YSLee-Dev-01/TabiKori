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
        ScrollView {
            LazyVStack(spacing: 0) {
                if self.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                } else if self.bookmarks.isEmpty {
                    TabiEmptyState(
                        systemImageName: "heart.slash",
                        title: Strings.Bookmark.emptyTitle,
                        description: Strings.Bookmark.emptyDescription
                    )
                    .padding(.horizontal, 20)
                } else {
                    ForEach(Array(self.bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                        PlanDetailAddSpotSpotRow(spot: bookmark.touristSpot) {
                            self.onSpotTapped(bookmark.touristSpot)
                        }
                        .padding(.horizontal, Self.rowHorizontalPadding)
                    }
                }
            }
        }
    }
}

// MARK: - View

private extension PlanDetailAddSpotBookmarkListView {
    /// TabiSpotRow는 내부에 16pt 패딩을 갖고 있어, 헤더/검색 모드와 동일한 20pt 여백을 맞추려면 4pt만 추가하면 된다
    static let rowHorizontalPadding: CGFloat = 4
}
