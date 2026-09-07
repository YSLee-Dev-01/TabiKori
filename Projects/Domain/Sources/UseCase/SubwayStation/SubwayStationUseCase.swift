//
//  SubwayStationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class SubwayStationUseCase: SubwayStationUseCaseProtocol {

    // MARK: - Properties

    private let subwayStationRepository: SubwayStationRepositoryProtocol

    // MARK: - Init

    public init(subwayStationRepository: SubwayStationRepositoryProtocol) {
        self.subwayStationRepository = subwayStationRepository
    }

    // MARK: - Method

    public func search(keyword: String) async -> [SubwayStation] {
        let matchedStations = await self.subwayStationRepository.searchLocal(keyword: keyword)
        return Array(matchedStations.prefix(Self.maxResultCount))
    }

    public func selectStation(_ station: SubwayStation) async throws -> TouristSpot {
        let coordinate = try await self.subwayStationRepository.fetchCoordinate(stationName: station.koreanName)
        let lineText = station.lineNumbers.joined(separator: "・")
        return TouristSpot(
            id: "subway_\(station.stationCode)",
            title: "\(station.displayJapaneseName)（\(station.koreanName)）",
            thumbnailURLString: nil,
            distanceMeters: nil,
            contentType: .subway,
            coordinate: coordinate,
            isCustom: false,
            isStation: true,
            address: lineText
        )
    }
}

// MARK: - Method

private extension SubwayStationUseCase {
    static let maxResultCount = 5
}
