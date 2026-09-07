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
    var startTime: Date?
    var durationMinutes: Int?
    var contentId: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var thumbnailURLString: String?
    var isCustom: Bool = true
    var isStation: Bool = false
    var address: String?

    init(
        id: UUID,
        planId: UUID,
        dayIndex: Int,
        order: Int,
        category: String,
        title: String,
        subtitle: String?,
        startTime: Date?,
        durationMinutes: Int?,
        contentId: String,
        latitude: Double,
        longitude: Double,
        thumbnailURLString: String?,
        isCustom: Bool,
        isStation: Bool = false,
        address: String?
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
        self.contentId = contentId
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailURLString = thumbnailURLString
        self.isCustom = isCustom
        self.isStation = isStation
        self.address = address
    }
}
