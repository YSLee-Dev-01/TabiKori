//
//  TouristSpotRepository.swift
//  Data
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class TouristSpotRepository: TouristSpotRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Init

    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Method

    public func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int,
        pageNo: Int
    ) async throws -> [TouristSpot] {
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.nearbySpots(
                contentType: contentType,
                coordinate: coordinate,
                radiusMeters: radiusMeters,
                pageNo: pageNo
            ),
            responseType: TouristSpotResponseDTO.self
        )
        return try dto.toEntities()
    }

    public func fetchRegionSpots(
        region: KoreanRegion,
        contentType: CategoryType,
        pageNo: Int
    ) async throws -> [TouristSpot] {
        guard region.areaCode != nil else {
            return []
        }
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.areaBasedSpots(
                region: region,
                contentType: contentType,
                pageNo: pageNo
            ),
            responseType: TouristSpotResponseDTO.self
        )
        return try dto.toEntities()
    }

    public func fetchDetail(contentId: String) async throws -> TouristSpotDetail {
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.detail(contentId: contentId),
            responseType: TouristSpotDetailResponseDTO.self
        )
        return try dto.toEntity()
    }

    public func fetchIntro(contentId: String, contentType: CategoryType) async throws -> TouristSpotIntro {
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.intro(contentId: contentId, contentType: contentType),
            responseType: TouristSpotIntroResponseDTO.self
        )
        return try dto.toEntity()
    }

    public func fetchImages(contentId: String) async throws -> [TouristSpotImage] {
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.images(contentId: contentId),
            responseType: TouristSpotImageResponseDTO.self
        )
        return try dto.toEntities()
    }

    public func searchByKeyword(keyword: String, pageNo: Int) async throws -> [TouristSpot] {
        let dto = try await self.networkService.request(
            endPoint: TouristSpotEndpoint.searchKeyword(keyword: keyword, pageNo: pageNo),
            responseType: TouristSpotResponseDTO.self
        )
        return try dto.toEntities()
    }
}
