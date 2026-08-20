//
//  SubwayStationGeomLocalDTO.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

struct SubwayStationGeomLocalRowDTO: Decodable {
    let stationNm: String
    let lineNum: String
    let x: Double
    let y: Double

    enum CodingKeys: String, CodingKey {
        case stationNm = "station_nm"
        case lineNum = "line_num"
        case x
        case y
    }
}

// MARK: - Mapping

extension [SubwayStationGeomLocalRowDTO] {
    /// station_nm(한국어 역명) 기준으로 환승역을 그룹핑해 대표 좌표 1개를 선택한다.
    /// geom 데이터 일부 역명에는 검색용 로컬 JSON(`seoul_subway_station.json`)에 없는
    /// "역명(부기명)" 형태의 반각 괄호 부기 표기(예: "흑석(중앙대입구)")가 섞여 있어,
    /// 그대로 키로 사용하면 `SubwayStationLocalFileDTO.toGroupedStations()`가 만드는 검색 결과의
    /// 순수 역명(예: "흑석")과 표기가 어긋나 좌표 조회가 실패한다 — 그룹핑 전 부기 표기를 제거해 흡수한다.
    /// 대표 로우는 line_num 오름차순 정렬 후 첫 로우로 결정적으로 고정한다 (검색마다 대표값이 바뀌지 않도록).
    /// `SubwayStationLocalFileDTO.toGroupedStations()`와 동일한 그룹핑 전략을 따른다.
    func toStationCoordinateMap() -> [String: Coordinate] {
        let groupedByName = Dictionary(grouping: self, by: { $0.stationNm.strippingParentheticalSuffix })
        return groupedByName.mapValues { rows in
            let sortedRows = rows.sorted { $0.lineNum < $1.lineNum }
            let representative = sortedRows[0]
            return Coordinate(latitude: representative.y, longitude: representative.x)
        }
    }
}

// MARK: - Normalization

private extension String {
    /// "역명(부기명)" 형태에서 괄호 및 부기 표기를 제거해 검색용 로컬 JSON과 동일한 기준 역명만 남긴다.
    var strippingParentheticalSuffix: String {
        guard let openRange = self.range(of: "(") else { return self }
        return String(self[self.startIndex ..< openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
}
