//
//  PlanDetailAddSpotSubwayStationRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct PlanDetailAddSpotSubwayStationRow: View {
    let station: SubwayStation
    let onTap: () -> Void

    var body: some View {
        TabiSpotRow(
            thumbnailURL: nil,
            japaneseTitle: self.station.displayJapaneseName,
            koreanTitle: self.station.koreanName,
            address: self.station.lineNumbers.joined(separator: "・"),
            tagTitle: CategoryType.subway.label,
            tagColor: CategoryType.subway.color,
            isCustom: false,
            distance: nil,
            onTap: self.onTap
        )
    }
}
