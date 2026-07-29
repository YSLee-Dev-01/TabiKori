//
//  TouristSpotRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TouristSpotRepositoryProtocol: Sendable {
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
