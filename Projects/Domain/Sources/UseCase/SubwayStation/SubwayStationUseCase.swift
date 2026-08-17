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
            title: "\(station.japaneseName.strippingParentheticalSuffix)（\(station.koreanName)）",
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

private extension String {
    /// 일부 역의 station_nm_jpn에 반각 괄호로 된 부가 표기(예: "(DDP)", "(新村)")가 섞여 있어
    /// TouristSpot.title의 전각 괄호 파싱 규칙(japaneseTitle/koreanTitle)과 충돌한다 — 제거 후 사용
    var strippingParentheticalSuffix: String {
        guard let openRange = self.range(of: "(") else { return self }
        return String(self[self.startIndex ..< openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
}
