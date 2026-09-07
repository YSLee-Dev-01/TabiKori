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

    private let localCache = SubwayStationLocalCache()
    private let geomCache = SubwayStationGeomCache()

    // MARK: - Init

    public init() {}

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

    public func fetchCoordinate(stationName: String) async throws -> Coordinate {
        let coordinateMap = await self.geomCache.stationCoordinateMap()
        guard let coordinate = coordinateMap[stationName] else {
            AppLogger.network.log(.error, "❌ 지하철역 좌표 조회 실패: \(stationName)")
            throw TabiError.dataNotFound
        }
        return coordinate
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

// MARK: - Geom Local JSON Cache

private actor SubwayStationGeomCache {
    private var cached: [String: Coordinate]?

    func stationCoordinateMap() async -> [String: Coordinate] {
        if let cached { return cached }

        guard let data = SubwayStationResource.loadGeomData() else {
            AppLogger.core.log(.error, "❌ 지하철역 좌표 로컬 JSON 로드 실패")
            self.cached = [:]
            return [:]
        }

        do {
            let rows = try JSONDecoder().decode([SubwayStationGeomLocalRowDTO].self, from: data)
            let coordinateMap = rows.toStationCoordinateMap()
            self.cached = coordinateMap
            return coordinateMap
        } catch {
            AppLogger.core.log(.error, "❌ 지하철역 좌표 로컬 JSON 파싱 실패: \(error.localizedDescription)")
            self.cached = [:]
            return [:]
        }
    }
}
