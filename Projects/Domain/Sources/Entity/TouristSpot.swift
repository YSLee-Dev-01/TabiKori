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
    public let coordinate: Coordinate
    public let isCustom: Bool
    public let isStation: Bool
    public let address: String?

    public init(
        id: String,
        title: String,
        thumbnailURLString: String?,
        distanceMeters: Double?,
        contentType: CategoryType,
        coordinate: Coordinate,
        isCustom: Bool = false,
        isStation: Bool = false,
        address: String? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbnailURLString = thumbnailURLString
        self.distanceMeters = distanceMeters
        self.contentType = contentType
        self.coordinate = coordinate
        self.isCustom = isCustom
        self.isStation = isStation
        self.address = address
    }

    public var thumbnailURL: URL? {
        return URL(string: self.thumbnailURLString ?? "")
    }

    /// isCustom과 isStation은 동시에 true가 될 수 없음 — 원격 상세 API 호출을 스킵해야 하는지 여부
    public var shouldSkipRemoteDetail: Bool {
        return self.isCustom || self.isStation
    }

    public var japaneseTitle: String {
        guard let openRange = self.title.rangeOfCharacter(from: Self.openParenthesisCharacters) else { return self.title }
        return String(self.title[self.title.startIndex ..< openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    public var koreanTitle: String? {
        guard let openRange = self.title.rangeOfCharacter(from: Self.openParenthesisCharacters),
              let closeRange = self.title.rangeOfCharacter(from: Self.closeParenthesisCharacters, range: openRange.upperBound ..< self.title.endIndex) else { return nil }
        let korean = String(self.title[openRange.upperBound ..< closeRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        return korean.isEmpty ? nil : korean
    }
}

// MARK: - Constants

private extension TouristSpot {
    static let openParenthesisCharacters = CharacterSet(charactersIn: "（(")
    static let closeParenthesisCharacters = CharacterSet(charactersIn: "）)")
}
