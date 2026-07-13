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

    public func fetchDetail(contentId: String) async throws -> TouristSpotDetail {
        return try await self.repository.fetchDetail(contentId: contentId)
    }

    public func fetchIntro(contentId: String, contentType: CategoryType) async throws -> TouristSpotIntro {
        return try await self.repository.fetchIntro(contentId: contentId, contentType: contentType)
    }

    public func fetchImages(contentId: String) async throws -> [TouristSpotImage] {
        return try await self.repository.fetchImages(contentId: contentId)
    }
}
