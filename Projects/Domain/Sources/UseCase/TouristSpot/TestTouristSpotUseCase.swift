//
//  TestTouristSpotUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTouristSpotUseCase: TouristSpotUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var nearbySpots: [TouristSpot] = []
    public var detail: TouristSpotDetail!
    public var intro: TouristSpotIntro!
    public var images: [TouristSpotImage] = []

    // MARK: - Method

    public func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int
    ) async throws -> [TouristSpot] {
        return self.nearbySpots
    }

    public func fetchDetail(contentId: String) async throws -> TouristSpotDetail {
        return self.detail
    }

    public func fetchIntro(contentId: String, contentType: CategoryType) async throws -> TouristSpotIntro {
        return self.intro
    }

    public func fetchImages(contentId: String) async throws -> [TouristSpotImage] {
        return self.images
    }
}
