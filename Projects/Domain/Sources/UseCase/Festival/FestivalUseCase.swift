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
        pageNo: Int
    ) async throws -> [Festival] {
        let festivals = try await self.repository.fetchFestivals(
            startDate: startDate,
            endDate: endDate,
            regionCode: regionCode,
            pageNo: pageNo
        )

        guard let endDate else {
            return festivals
        }
        return festivals.filter { festival in
            festival.startDate >= startDate && (festival.endDate ?? festival.startDate) <= endDate
        }
    }

    public func fetchRegions() async throws -> [LDongRegion] {
        return try await self.repository.fetchRegions()
    }
}
