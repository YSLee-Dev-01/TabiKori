//
//  NaverGeocodingUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class NaverGeocodingUseCase: NaverGeocodingUseCaseProtocol {

    // MARK: - Properties

    private let repository: NaverGeocodingRepositoryProtocol

    // MARK: - Init

    public init(repository: NaverGeocodingRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func geocode(address: String) async throws -> GeocodedAddress {
        return try await self.repository.geocode(address: address)
    }
}
