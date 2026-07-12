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

    public var japaneseTitle: String {
        guard let range = self.title.range(of: "（") else { return self.title }
        return String(self.title[self.title.startIndex ..< range.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    public var koreanTitle: String? {
        guard let openRange = self.title.range(of: "（"),
              let closeRange = self.title.range(of: "）") else { return nil }
        let korean = String(self.title[openRange.upperBound ..< closeRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        return korean.isEmpty ? nil : korean
    }
}
