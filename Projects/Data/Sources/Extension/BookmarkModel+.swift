//
//  BookmarkModel+.swift
//  Data
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

extension BookmarkModel {
    var toDomain: Bookmark? {
        guard let contentType = CategoryType(rawValue: self.contentTypeRaw) else {
            AppLogger.core.log(.error, "북마크 contentType 복원 실패: \(self.contentId)")
            return nil
        }

        let touristSpot = TouristSpot(
            id: self.contentId,
            title: self.title,
            thumbnailURLString: self.thumbnailURLString,
            distanceMeters: nil,
            contentType: contentType,
            coordinate: Coordinate(latitude: self.latitude, longitude: self.longitude),
            isCustom: self.isCustom,
            address: self.address
        )
        return Bookmark(touristSpot: touristSpot, savedAt: self.savedAt)
    }

    convenience init(spot: TouristSpot, savedAt: Date) {
        self.init(
            contentId: spot.id,
            title: spot.title,
            thumbnailURLString: spot.thumbnailURLString,
            contentTypeRaw: spot.contentType.rawValue,
            latitude: spot.coordinate.latitude,
            longitude: spot.coordinate.longitude,
            savedAt: savedAt,
            isCustom: spot.isCustom,
            address: spot.address
        )
    }
}
