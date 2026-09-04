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

    /// 한국관광공사 API가 반환하는 이미지 URL이 http 스킴이면, ATS(App Transport Security) 정책에 막혀
    /// 로드되지 않으므로 https로 승격해 사용한다
    public var thumbnailURL: URL? {
        guard let thumbnailURLString else { return nil }
        guard thumbnailURLString.hasPrefix("http://") else {
            return URL(string: thumbnailURLString)
        }
        return URL(string: "https://" + thumbnailURLString.dropFirst("http://".count))
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
