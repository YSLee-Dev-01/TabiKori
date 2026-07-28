//
//  MapSearchResultRowView.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct MapSearchResultRowView: View {

    var spot: TouristSpot
    var onTapped: () -> Void

    var body: some View {
        TabiSpotRow(
            thumbnailURL: self.spot.thumbnailURL,
            japaneseTitle: self.spot.japaneseTitle,
            koreanTitle: self.spot.koreanTitle,
            tagTitle: self.spot.contentType.label,
            tagColor: self.spot.contentType.color,
            distance: self.spot.formattedDistance,
            onTap: self.onTapped
        )
    }
}

// MARK: - TouristSpot View Extension

private extension TouristSpot {
    var formattedDistance: String? {
        guard let dist = self.distanceMeters else { return nil }
        if dist >= 1000 { return String(format: "%.1fkm", dist / 1000) }
        return "\(Int(dist))m"
    }
}
