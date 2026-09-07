//
//  TravelPlanModel+.swift
//  Data
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

extension TravelPlanModel {
    var toDomain: TravelPlan? {
        guard let region = KoreanRegion(rawValue: self.regionRaw) else {
            AppLogger.core.log(.error, "일정 region 복원 실패: \(self.id)")
            return nil
        }

        return TravelPlan(
            id: self.id,
            title: self.title,
            region: region,
            customRegionText: self.customRegionText,
            customEmoji: self.customEmoji,
            startDate: self.startDate,
            endDate: self.endDate
        )
    }

    convenience init(plan: TravelPlan) {
        self.init(
            id: plan.id,
            title: plan.title,
            regionRaw: plan.region.rawValue,
            customRegionText: plan.customRegionText,
            customEmoji: plan.customEmoji,
            startDate: plan.startDate,
            endDate: plan.endDate
        )
    }
}
