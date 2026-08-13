//
//  RegionSpotFestivalSection.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct RegionSpotFestivalSection: View {
    var loadState: RegionSpotLoadState
    var festivals: [Festival]
    var onRetry: () -> Void
    var onFestivalTapped: (Festival) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch self.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

            case .failed:
                VStack(spacing: 12) {
                    TabiEmptyState(
                        systemImageName: "exclamationmark.triangle",
                        description: Strings.RegionSpot.errorDescription,
                        style: .card
                    )
                    TabiButton(Strings.RegionSpot.retryButtonTitle, style: .secondary, action: self.onRetry)
                }
                .padding(.horizontal, 20)

            case .loaded where self.festivals.isEmpty:
                VStack(spacing: 12) {
                    TabiEmptyState(
                        systemImageName: "calendar.badge.exclamationmark",
                        description: Strings.RegionSpot.festivalEmptyDescription,
                        style: .card
                    )
                    TabiButton(Strings.RegionSpot.retryButtonTitle, style: .secondary, action: self.onRetry)
                }
                .padding(.horizontal, 20)

            case .loaded:
                LazyVStack(spacing: 0) {
                    ForEach(self.festivals) { festival in
                        TabiFestivalRow(
                            thumbnailURL: festival.touristSpot.thumbnailURL,
                            japaneseTitle: festival.touristSpot.japaneseTitle,
                            koreanTitle: festival.touristSpot.koreanTitle,
                            periodTitle: festival.periodTitle,
                            onTap: { self.onFestivalTapped(festival) }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .animation(.tabiStandard, value: self.loadState)
    }
}
