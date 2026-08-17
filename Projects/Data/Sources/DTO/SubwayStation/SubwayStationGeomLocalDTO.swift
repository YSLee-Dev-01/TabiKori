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
    /// 대표 로우는 line_num 오름차순 정렬 후 첫 로우로 결정적으로 고정한다 (검색마다 대표값이 바뀌지 않도록).
    /// `SubwayStationLocalFileDTO.toGroupedStations()`와 동일한 그룹핑 전략을 따른다.
    func toStationCoordinateMap() -> [String: Coordinate] {
        let groupedByName = Dictionary(grouping: self, by: { $0.stationNm })
        return groupedByName.mapValues { rows in
            let sortedRows = rows.sorted { $0.lineNum < $1.lineNum }
            let representative = sortedRows[0]
            return Coordinate(latitude: representative.y, longitude: representative.x)
        }
    }
}
