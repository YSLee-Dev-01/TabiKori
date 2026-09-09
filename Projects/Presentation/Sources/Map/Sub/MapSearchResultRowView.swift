//
//  MapSearchResultRowView.swift
//  Presentation
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Core
import DesignSystem
import Domain

struct MapSearchResultRowView: View {

    var spot: TouristSpot
    var onTapped: () -> Void

    var body: some View {
        TabiSpotRow(
            thumbnailURL: self.spot.thumbnailURL,
            japaneseTitle: self.mainTitle,
            koreanTitle: self.subTitle,
            address: self.spot.address,
            tagTitle: self.spot.contentType.label,
            tagColor: self.spot.contentType.color,
            isCustom: self.spot.isCustom,
            distance: self.spot.formattedDistance,
            onTap: self.onTapped
        )
    }
}

// MARK: - Method

private extension MapSearchResultRowView {
    /// 로케일이 한국어이고 한국어 표기가 존재하면 한국어를 메인(볼드)으로 표시
    var mainTitle: String {
        if Locale.isKoreanLanguage, let koreanTitle = self.spot.koreanTitle?.removingBracketedTags {
            return koreanTitle
        }
        return self.spot.japaneseTitle.removingBracketedTags
    }

    var subTitle: String? {
        if Locale.isKoreanLanguage, self.spot.koreanTitle != nil {
            return self.spot.japaneseTitle.removingBracketedTags
        }
        return self.spot.koreanTitle?.removingBracketedTags
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
