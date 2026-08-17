//
//  SubwayStationRepository.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain
import Resource

public final class SubwayStationRepository: SubwayStationRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol
    private let localCache = SubwayStationLocalCache()
    private let confirmCache = SubwayStationConfirmCache()

    // MARK: - Init

    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Method

    public func searchLocal(keyword: String) async -> [SubwayStation] {
        let normalizedKeyword = keyword.subwayStationSearchKey
        guard normalizedKeyword.isEmpty == false else { return [] }

        let indexedStations = await self.localCache.indexedStations()
        let prefixMatches = indexedStations.filter {
            $0.normalizedKoreanName.hasPrefix(normalizedKeyword) || $0.normalizedJapaneseName.hasPrefix(normalizedKeyword)
        }
        let prefixMatchedCodes = Set(prefixMatches.map { $0.station.stationCode })
        let containsOnlyMatches = indexedStations.filter {
            guard prefixMatchedCodes.contains($0.station.stationCode) == false else { return false }
            return $0.normalizedKoreanName.contains(normalizedKeyword) || $0.normalizedJapaneseName.contains(normalizedKeyword)
        }
        return (prefixMatches + containsOnlyMatches).map { $0.station }
    }

    public func confirmExists(stationName: String) async throws -> Bool {
        if let cached = await self.confirmCache.value(for: stationName) {
            return cached
        }

        let dto = try await self.networkService.request(
            endPoint: SubwayStationEndpoint.search(stationName: stationName),
            responseType: SubwayStationSearchResponseDTO.self
        )
        let exists = try dto.toExistsResult()
        await self.confirmCache.set(exists, for: stationName)
        return exists
    }
}

// MARK: - Local JSON Cache

private struct IndexedSubwayStation {
    let station: SubwayStation
    let normalizedKoreanName: String
    let normalizedJapaneseName: String
}

private actor SubwayStationLocalCache {
    private var cached: [IndexedSubwayStation]?

    func indexedStations() async -> [IndexedSubwayStation] {
        if let cached { return cached }

        guard let data = SubwayStationResource.loadData() else {
            AppLogger.core.log(.error, "❌ 지하철역 로컬 JSON 로드 실패")
            self.cached = []
            return []
        }

        do {
            let file = try JSONDecoder().decode(SubwayStationLocalFileDTO.self, from: data)
            let indexed = file.toGroupedStations().map {
                IndexedSubwayStation(
                    station: $0,
                    normalizedKoreanName: $0.koreanName.subwayStationSearchKey,
                    normalizedJapaneseName: $0.japaneseName.subwayStationSearchKey
                )
            }
            self.cached = indexed
            return indexed
        } catch {
            AppLogger.core.log(.error, "❌ 지하철역 로컬 JSON 파싱 실패: \(error.localizedDescription)")
            self.cached = []
            return []
        }
    }
}

// MARK: - Remote Confirm Cache

private actor SubwayStationConfirmCache {
    private var cached: [String: Bool] = [:]

    func value(for stationName: String) -> Bool? {
        return self.cached[stationName]
    }

    func set(_ exists: Bool, for stationName: String) {
        self.cached[stationName] = exists
    }
}
