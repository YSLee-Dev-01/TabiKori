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
    public let thumbnailURLString: String?
    public let distanceMeters: Double?
    public let contentType: CategoryType

    public init(
        id: String,
        title: String,
        thumbnailURLString: String?,
        distanceMeters: Double?,
        contentType: CategoryType
    ) {
        self.id = id
        self.title = title
        self.thumbnailURLString = thumbnailURLString
        self.distanceMeters = distanceMeters
        self.contentType = contentType
    }
    
    public var thumbnailURL: URL? {
        return URL(string: self.thumbnailURLString ?? "")
    }
}
