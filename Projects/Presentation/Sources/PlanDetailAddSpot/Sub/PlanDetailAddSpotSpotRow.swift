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
            japaneseTitle: self.spot.japaneseTitle.removingBracketedTags,
            koreanTitle: self.spot.koreanTitle?.removingBracketedTags,
            address: self.spot.address,
            tagTitle: self.spot.contentType.label,
            tagColor: self.spot.contentType.color,
            isCustom: self.spot.isCustom,
            distance: nil,
            onTap: self.onTap
        )
    }
}
