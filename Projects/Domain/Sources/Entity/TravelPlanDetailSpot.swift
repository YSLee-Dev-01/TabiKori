//
//  TravelPlanDetailSpot.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TravelPlanDetailSpot: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let dayIndex: Int
    public let order: Int
    public let category: CategoryType
    public let title: String
    public let subtitle: String?
    public let startTime: Date?
    public let durationMinutes: Int?
    public let contentId: String
    public let coordinate: Coordinate
    public let thumbnailURLString: String?
    public let isCustom: Bool
    public let isStation: Bool
    public let address: String?

    public init(
        id: UUID,
        dayIndex: Int,
        order: Int,
        category: CategoryType,
        title: String,
        subtitle: String?,
        startTime: Date?,
        durationMinutes: Int?,
        contentId: String,
        coordinate: Coordinate,
        thumbnailURLString: String?,
        isCustom: Bool,
        isStation: Bool = false,
        address: String?
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.order = order
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.contentId = contentId
        self.coordinate = coordinate
        self.thumbnailURLString = thumbnailURLString
        self.isCustom = isCustom
        self.isStation = isStation
        self.address = address
    }
}
