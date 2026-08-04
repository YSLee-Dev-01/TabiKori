//
//  FestivalRepository.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class FestivalRepository: FestivalRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Init

    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Method

    public func fetchFestivals(
        startDate: Date,
        endDate: Date?,
        regionCode: String?,
        pageNo: Int
    ) async throws -> [Festival] {
        let dto = try await self.networkService.request(
            endPoint: FestivalEndpoint.searchFestival(
                startDate: startDate,
                endDate: endDate,
                regionCode: regionCode,
                pageNo: pageNo
            ),
            responseType: FestivalResponseDTO.self
        )
        return try dto.toEntities()
    }

    public func fetchRegions() async throws -> [LDongRegion] {
        let dto = try await self.networkService.request(
            endPoint: FestivalEndpoint.ldongCode,
            responseType: LDongRegionResponseDTO.self
        )
        return try dto.toEntities()
    }
}
