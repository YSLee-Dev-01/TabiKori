//
//  FestivalUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum FestivalSearchPeriod {
    public static let defaultDurationDays = 30
}

public protocol FestivalUseCaseProtocol: Sendable {
    func fetchFestivals(
        startDate: Date,
        endDate: Date?,
        regionCode: String?,
        sigunguCode: String?,
        pageNo: Int
    ) async throws -> [Festival]

    func fetchRegionFestivals(
        startDate: Date,
        endDate: Date?,
        region: KoreanRegion,
        pageNo: Int
    ) async throws -> [Festival]

    func fetchRegions() async throws -> [LDongRegion]
}
