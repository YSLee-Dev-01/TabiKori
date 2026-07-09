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

    // MARK: - Method

    public func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int
    ) async throws -> [TouristSpot] {
        return self.nearbySpots
    }
}
