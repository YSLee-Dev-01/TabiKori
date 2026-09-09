//
//  PlanDetailAddSpotSpotRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Core
import DesignSystem
import Domain

struct PlanDetailAddSpotSpotRow: View {
    let spot: TouristSpot
    let onTap: () -> Void

    var body: some View {
        TabiSpotRow(
            thumbnailURL: self.spot.thumbnailURL,
            japaneseTitle: self.mainTitle,
            koreanTitle: self.subTitle,
            address: self.spot.address,
            tagTitle: self.spot.contentType.label,
            tagColor: self.spot.contentType.color,
            isCustom: self.spot.isCustom,
            distance: nil,
            onTap: self.onTap
        )
    }
}

// MARK: - Method

private extension PlanDetailAddSpotSpotRow {
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
