//
//  Bookmark.swift
//  Domain
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct Bookmark: Equatable, Sendable, Identifiable {
    public let touristSpot: TouristSpot
    public let savedAt: Date

    public init(touristSpot: TouristSpot, savedAt: Date) {
        self.touristSpot = touristSpot
        self.savedAt = savedAt
    }

    public var id: String {
        return self.touristSpot.id
    }
}
