//
//  TestSubwayStationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestSubwayStationUseCase: SubwayStationUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var searchResults: [SubwayStation] = []
    public var selectedTouristSpot: TouristSpot = TouristSpot(
        id: "subway_test",
        title: "",
        thumbnailURLString: nil,
        distanceMeters: nil,
        contentType: .subway,
        coordinate: .seoulCityHall,
        isCustom: false,
        isStation: true,
        address: nil
    )
    public var selectStationError: Error?

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func search(keyword: String) async -> [SubwayStation] {
        return self.searchResults
    }

    public func selectStation(_ station: SubwayStation) async throws -> TouristSpot {
        if let selectStationError {
            throw selectStationError
        }
        return self.selectedTouristSpot
    }
}
