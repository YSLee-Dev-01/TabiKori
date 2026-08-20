//
//  MapSubwayStationRowView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct MapSubwayStationRowView: View {

    var station: SubwayStation
    var onTapped: () -> Void

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
            onTap: self.onTapped
        )
    }
}
