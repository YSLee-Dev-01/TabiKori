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
            japaneseTitle: self.mainTitle,
            koreanTitle: self.subTitle,
            address: self.station.lineNumbers.joined(separator: "・"),
            tagTitle: CategoryType.subway.label,
            tagColor: CategoryType.subway.color,
            isCustom: false,
            distance: nil,
            onTap: self.onTap
        )
    }
}

// MARK: - Method

private extension PlanDetailAddSpotSubwayStationRow {
    /// 로케일이 한국어이면 한국어 역명을 메인(볼드)으로 표시
    var mainTitle: String {
        Locale.isKoreanLanguage ? self.station.koreanName : self.station.displayJapaneseName
    }

    var subTitle: String {
        Locale.isKoreanLanguage ? self.station.displayJapaneseName : self.station.koreanName
    }
}
