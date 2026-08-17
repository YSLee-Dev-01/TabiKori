//
//  FestivalUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class FestivalUseCase: FestivalUseCaseProtocol {

    // MARK: - Properties

    private let repository: FestivalRepositoryProtocol

    // MARK: - Init

    public init(repository: FestivalRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchFestivals(
        startDate: Date,
        endDate: Date?,
        regionCode: String?,
        sigunguCode: String?,
        pageNo: Int
    ) async throws -> [Festival] {
        let festivals = try await self.repository.fetchFestivals(
            startDate: startDate,
            endDate: endDate,
            regionCode: regionCode,
            sigunguCode: sigunguCode,
            pageNo: pageNo
        )
        return self.filterFestivals(festivals, startDate: startDate, endDate: endDate)
    }

    public func fetchRegionFestivals(
        startDate: Date,
        endDate: Date?,
        region: KoreanRegion,
        pageNo: Int
    ) async throws -> [Festival] {
        let festivals = try await self.repository.fetchRegionFestivals(
            startDate: startDate,
            endDate: endDate,
            region: region,
            pageNo: pageNo
        )
        return self.filterFestivals(festivals, startDate: startDate, endDate: endDate)
    }

    public func fetchRegions() async throws -> [LDongRegion] {
        return try await self.repository.fetchRegions()
    }
}

// MARK: - Method

private extension FestivalUseCase {
    func filterFestivals(_ festivals: [Festival], startDate: Date, endDate: Date?) -> [Festival] {
        guard let endDate else {
            return festivals
        }
        return festivals.filter { festival in
            festival.startDate >= startDate && (festival.endDate ?? festival.startDate) <= endDate
        }
    }
}
