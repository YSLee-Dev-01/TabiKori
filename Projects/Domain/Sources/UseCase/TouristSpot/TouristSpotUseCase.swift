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
        radiusMeters: Int,
        pageNo: Int
    ) async throws -> [TouristSpot] {
        return try await self.repository.fetchNearbySpots(
            contentType: contentType,
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            pageNo: pageNo
        )
    }

    public func fetchRegionSpots(
        region: KoreanRegion,
        contentType: CategoryType,
        pageNo: Int
    ) async throws -> [TouristSpot] {
        return try await self.repository.fetchRegionSpots(
            region: region,
            contentType: contentType,
            pageNo: pageNo
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

    public func searchByKeyword(keyword: String, pageNo: Int) async throws -> [TouristSpot] {
        return try await self.repository.searchByKeyword(keyword: keyword, pageNo: pageNo)
    }
}
