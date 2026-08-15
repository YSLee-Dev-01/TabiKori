//
//  TravelPlanModel.swift
//  Data
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class TravelPlanModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var regionRaw: String
    var customRegionText: String?
    var customEmoji: String?
    var startDate: Date
    var endDate: Date

    init(
        id: UUID,
        title: String,
        regionRaw: String,
        customRegionText: String?,
        customEmoji: String?,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.title = title
        self.regionRaw = regionRaw
        self.customRegionText = customRegionText
        self.customEmoji = customEmoji
        self.startDate = startDate
        self.endDate = endDate
    }
}
