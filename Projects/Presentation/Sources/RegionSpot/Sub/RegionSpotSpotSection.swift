//
//  RegionSpotSpotSection.swift
//  Presentation
//
//  Created by 이윤수 on 8/10/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct RegionSpotSpotSection: View {
    var loadState: RegionSpotLoadState
    var spots: [TouristSpot]
    var onRetry: () -> Void
    var onSpotTapped: (TouristSpot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch self.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)

            case .failed:
                TabiRetryableEmptyState(description: Strings.RegionSpot.errorDescription, onRetry: self.onRetry)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)

            case .loaded where self.spots.isEmpty:
                TabiEmptyState(
                    systemImageName: "mappin.slash",
                    title: Strings.RegionSpot.spotEmptyTitle,
                    description: Strings.RegionSpot.spotEmptyDescription
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 24)

            case .loaded:
                LazyVStack(spacing: 0) {
                    ForEach(self.spots) { spot in
                        TabiSpotRow(
                            thumbnailURL: spot.thumbnailURL,
                            japaneseTitle: spot.japaneseTitle,
                            koreanTitle: spot.koreanTitle,
                            tagTitle: spot.contentType.label,
                            tagColor: spot.contentType.color,
                            isCustom: spot.isCustom,
                            distance: nil,
                            onTap: { self.onSpotTapped(spot) }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .animation(.tabiStandard, value: self.loadState)
    }
}
