//
//  TouristSpotUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TouristSpotSearchRadius {
    public static let nearbyMeters = 10000
    public static let minMeters = 500
    public static let maxMeters = 15000
}

public protocol TouristSpotUseCaseProtocol: Sendable {
    func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int,
        pageNo: Int
    ) async throws -> [TouristSpot]

    func fetchDetail(contentId: String) async throws -> TouristSpotDetail

    func fetchIntro(contentId: String, contentType: CategoryType) async throws -> TouristSpotIntro

    func fetchImages(contentId: String) async throws -> [TouristSpotImage]

    func searchByKeyword(keyword: String, pageNo: Int) async throws -> [TouristSpot]
}
