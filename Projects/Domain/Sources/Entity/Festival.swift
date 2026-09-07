//
//  Festival.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct Festival: Equatable, Sendable, Identifiable {
    public let touristSpot: TouristSpot
    public let startDate: Date
    public let endDate: Date?

    public init(touristSpot: TouristSpot, startDate: Date, endDate: Date?) {
        self.touristSpot = touristSpot
        self.startDate = startDate
        self.endDate = endDate
    }

    public var id: String {
        return self.touristSpot.id
    }
}
