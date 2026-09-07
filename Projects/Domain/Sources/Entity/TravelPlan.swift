//
//  TravelPlan.swift
//  Domain
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TravelPlan: Equatable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var region: KoreanRegion
    public var customRegionText: String?
    public var customEmoji: String?
    public var startDate: Date
    public var endDate: Date

    public init(
        id: UUID,
        title: String,
        region: KoreanRegion,
        customRegionText: String?,
        customEmoji: String?,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.title = title
        self.region = region
        self.customRegionText = customRegionText
        self.customEmoji = customEmoji
        self.startDate = startDate
        self.endDate = endDate
    }
}
