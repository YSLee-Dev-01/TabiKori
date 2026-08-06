//
//  NaverGeocodingRepository.swift
//  Data
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class NaverGeocodingRepository: NaverGeocodingRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Init

    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Method

    public func geocode(address: String) async throws -> Coordinate {
        let dto = try await self.networkService.request(
            endPoint: NaverGeocodingEndpoint.geocode(address: address),
            responseType: NaverGeocodingResponseDTO.self
        )
        return try dto.toEntity()
    }
}
