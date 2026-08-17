//
//  SubwayStationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core

public final class SubwayStationUseCase: SubwayStationUseCaseProtocol {

    // MARK: - Properties

    private let subwayStationRepository: SubwayStationRepositoryProtocol
    private let naverGeocodingRepository: NaverGeocodingRepositoryProtocol

    // MARK: - Init

    public init(
        subwayStationRepository: SubwayStationRepositoryProtocol,
        naverGeocodingRepository: NaverGeocodingRepositoryProtocol
    ) {
        self.subwayStationRepository = subwayStationRepository
        self.naverGeocodingRepository = naverGeocodingRepository
    }

    // MARK: - Method

    public func search(keyword: String) async -> [TouristSpot] {
        let matchedStations = await self.subwayStationRepository.searchLocal(keyword: keyword)
        let topStations = Array(matchedStations.prefix(Self.maxResultCount))
        guard topStations.isEmpty == false else { return [] }

        return await withTaskGroup(of: (Int, TouristSpot?).self) { group in
            for (index, station) in topStations.enumerated() {
                group.addTask { [subwayStationRepository, naverGeocodingRepository] in
                    let resolved = await Self.resolve(
                        station: station,
                        subwayStationRepository: subwayStationRepository,
                        naverGeocodingRepository: naverGeocodingRepository
                    )
                    return (index, resolved)
                }
            }

            var indexedResults: [(index: Int, spot: TouristSpot)] = []
            for await (index, result) in group {
                if let result {
                    indexedResults.append((index, result))
                }
            }
            // 병렬 완료 순서가 아니라 로컬 매칭 우선순위(prefix 매치 우선) 순서를 그대로 보존
            return indexedResults.sorted { $0.index < $1.index }.map { $0.spot }
        }
    }
}

// MARK: - Method

private extension SubwayStationUseCase {
    static let maxResultCount = 5

    static func resolve(
        station: SubwayStation,
        subwayStationRepository: SubwayStationRepositoryProtocol,
        naverGeocodingRepository: NaverGeocodingRepositoryProtocol
    ) async -> TouristSpot? {
        do {
            let exists = try await subwayStationRepository.confirmExists(stationName: station.koreanName)
            guard exists else { return nil }
        } catch is CancellationError {
            return nil
        } catch {
            guard !Task.isCancelled else { return nil }
            AppLogger.network.log(.error, "지하철역 실재 확인 실패: \(station.koreanName) - \(error.localizedDescription)")
            return nil
        }

        let representativeLine = station.lineNumbers.first ?? ""
        let geocodeQuery = "\(representativeLine) \(station.koreanName)역"

        do {
            let geocoded = try await naverGeocodingRepository.geocode(address: geocodeQuery)
            let lineText = station.lineNumbers.joined(separator: "・")
            return TouristSpot(
                id: "subway_\(station.stationCode)",
                title: "\(station.japaneseName.strippingParentheticalSuffix)（\(station.koreanName)）",
                thumbnailURLString: nil,
                distanceMeters: nil,
                contentType: .subway,
                coordinate: geocoded.coordinate,
                isCustom: false,
                isStation: true,
                address: "\(lineText) · \(geocoded.formattedAddress)"
            )
        } catch is CancellationError {
            return nil
        } catch {
            guard !Task.isCancelled else { return nil }
            AppLogger.network.log(.error, "지하철역 지오코딩 실패: \(station.koreanName) - \(error.localizedDescription)")
            return nil
        }
    }
}

private extension String {
    /// 일부 역의 station_nm_jpn에 반각 괄호로 된 부가 표기(예: "(DDP)", "(新村)")가 섞여 있어
    /// TouristSpot.title의 전각 괄호 파싱 규칙(japaneseTitle/koreanTitle)과 충돌한다 — 제거 후 사용
    var strippingParentheticalSuffix: String {
        guard let openRange = self.range(of: "(") else { return self }
        return String(self[self.startIndex ..< openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
}
