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
            durationMinutes: self.durationMinutes,
            contentId: self.contentId,
            coordinate: Coordinate(latitude: self.latitude, longitude: self.longitude),
            thumbnailURLString: self.thumbnailURLString,
            isCustom: self.isCustom,
            address: self.address
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
            durationMinutes: spot.durationMinutes,
            contentId: spot.contentId,
            latitude: spot.coordinate.latitude,
            longitude: spot.coordinate.longitude,
            thumbnailURLString: spot.thumbnailURLString,
            isCustom: spot.isCustom,
            address: spot.address
        )
    }
}
