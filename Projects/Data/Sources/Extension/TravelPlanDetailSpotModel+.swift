//
//  TravelPlanDetailSpotModel+.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

extension TravelPlanDetailSpotModel {
    var toDomain: TravelPlanDetailSpot? {
        guard let category = CategoryType(rawValue: self.category) else {
            AppLogger.core.log(.error, "TravelPlanDetailSpotModel category 파싱 실패: \(self.category)")
            return nil
        }
        return TravelPlanDetailSpot(
            id: self.id,
            dayIndex: self.dayIndex,
            order: self.order,
            category: category,
            title: self.title,
            subtitle: self.subtitle,
            startTime: self.startTime,
            durationMinutes: self.durationMinutes
        )
    }

    convenience init(spot: TravelPlanDetailSpot, planId: UUID) {
        self.init(
            id: spot.id,
            planId: planId,
            dayIndex: spot.dayIndex,
            order: spot.order,
            category: spot.category.rawValue,
            title: spot.title,
            subtitle: spot.subtitle,
            startTime: spot.startTime,
            durationMinutes: spot.durationMinutes
        )
    }
}
