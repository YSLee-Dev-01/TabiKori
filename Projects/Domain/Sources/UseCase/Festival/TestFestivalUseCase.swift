//
//  TestFestivalUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestFestivalUseCase: FestivalUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var festivals: [Festival] = []
    public var regions: [LDongRegion] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchFestivals(
        startDate: Date,
        endDate: Date?,
        regionCode: String?,
        pageNo: Int
    ) async throws -> [Festival] {
        return self.festivals
    }

    public func fetchRegions() async throws -> [LDongRegion] {
        return self.regions
    }
}
