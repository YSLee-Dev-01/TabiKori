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
    public let contentType: CategoryType

    public init(
        id: String,
        title: String,
        thumbnailURL: String?,
        distanceMeters: Double?,
        contentType: CategoryType
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.distanceMeters = distanceMeters
        self.contentType = contentType
    }
}
