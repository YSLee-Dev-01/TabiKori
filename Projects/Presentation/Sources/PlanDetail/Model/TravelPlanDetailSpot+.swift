//
//  TravelPlanDetailSpot+.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import DesignSystem
import Domain
import Resource

extension TravelPlanDetailSpot {
    var startTimeTitle: String {
        self.startTime.planSpotTimeTitle
    }

    var durationTitle: String {
        Strings.Plan.spotDurationTitle(self.durationMinutes)
    }

    func toMapMarker(index: Int) -> TabiMapMarker? {
        guard self.coordinate.isValid else { return nil }
        return TabiMapMarker(
            id: self.id.uuidString,
            latitude: self.coordinate.latitude,
            longitude: self.coordinate.longitude,
            title: self.title.truncated(to: 15),
            icon: self.category.icon,
            color: self.category.color,
            index: index
        )
    }
}
