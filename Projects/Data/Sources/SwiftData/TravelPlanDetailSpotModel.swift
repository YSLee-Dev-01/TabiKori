//
//  TravelPlanDetailSpotModel.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class TravelPlanDetailSpotModel {
    @Attribute(.unique) var id: UUID
    var planId: UUID
    var dayIndex: Int
    var order: Int
    var category: String
    var title: String
    var subtitle: String?
    var startTime: Date
    var durationMinutes: Int

    init(
        id: UUID,
        planId: UUID,
        dayIndex: Int,
        order: Int,
        category: String,
        title: String,
        subtitle: String?,
        startTime: Date,
        durationMinutes: Int
    ) {
        self.id = id
        self.planId = planId
        self.dayIndex = dayIndex
        self.order = order
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.startTime = startTime
        self.durationMinutes = durationMinutes
    }
}
