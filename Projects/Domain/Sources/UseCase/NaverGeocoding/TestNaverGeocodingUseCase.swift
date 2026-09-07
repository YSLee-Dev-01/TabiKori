//
//  TestNaverGeocodingUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestNaverGeocodingUseCase: NaverGeocodingUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var coordinate: Coordinate = .seoulCityHall
    public var formattedAddress: String = ""
    public var error: Error?

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func geocode(address: String) async throws -> GeocodedAddress {
        if let error {
            throw error
        }
        return GeocodedAddress(coordinate: self.coordinate, formattedAddress: self.formattedAddress)
    }
}
