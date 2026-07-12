//
//  TouristSpotDetail.swift
//  Domain
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TouristSpotDetail: Equatable, Sendable {
    public let id: String
    public let title: String
    public let contentType: CategoryType
    public let tel: String?
    public let homepageURLString: String?
    public let imageURLString: String?
    public let address: String
    public let coordinate: Coordinate
    public let overview: String?

    public init(
        id: String,
        title: String,
        contentType: CategoryType,
        tel: String?,
        homepageURLString: String?,
        imageURLString: String?,
        address: String,
        coordinate: Coordinate,
        overview: String?
    ) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.tel = tel
        self.homepageURLString = homepageURLString
        self.imageURLString = imageURLString
        self.address = address
        self.coordinate = coordinate
        self.overview = overview
    }

    public var imageURL: URL? {
        return URL(string: self.imageURLString ?? "")
    }

    public var homepageURL: URL? {
        return URL(string: self.homepageURLString ?? "")
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
