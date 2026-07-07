//
//  TouristSpot.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TouristSpot: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let thumbnailURL: String?
    public let distanceMeters: Double?
    public let contentType: TouristSpotContentType

    public init(
        id: String,
        title: String,
        thumbnailURL: String?,
        distanceMeters: Double?,
        contentType: TouristSpotContentType
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.distanceMeters = distanceMeters
        self.contentType = contentType
    }
}

public enum TouristSpotContentType: String, Equatable, CaseIterable, Sendable {
    case touristSpot
    case culturalFacility
    case festival
    case leisure
    case accommodation
    case shopping
    case restaurant
}
