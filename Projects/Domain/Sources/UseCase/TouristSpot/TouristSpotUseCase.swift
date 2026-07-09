//
//  TouristSpotUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TouristSpotUseCase: TouristSpotUseCaseProtocol {

    // MARK: - Properties

    private let repository: TouristSpotRepositoryProtocol

    // MARK: - Init

    public init(repository: TouristSpotRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int
    ) async throws -> [TouristSpot] {
        return try await self.repository.fetchNearbySpots(
            contentType: contentType,
            coordinate: coordinate,
            radiusMeters: radiusMeters
        )
    }
}
