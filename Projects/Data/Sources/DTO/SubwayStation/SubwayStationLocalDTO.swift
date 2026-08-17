//
//  SubwayStationLocalDTO.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

struct SubwayStationLocalFileDTO: Decodable {
    let data: [SubwayStationLocalRowDTO]

    enum CodingKeys: String, CodingKey {
        case data = "DATA"
    }
}

struct SubwayStationLocalRowDTO: Decodable {
    let lineNum: String
    let stationCd: String
    let stationNm: String
    let stationNmJpn: String
    let frCode: String

    enum CodingKeys: String, CodingKey {
        case lineNum = "line_num"
        case stationCd = "station_cd"
        case stationNm = "station_nm"
        case stationNmJpn = "station_nm_jpn"
        case frCode = "fr_code"
    }
}

// MARK: - Mapping

extension SubwayStationLocalFileDTO {
    /// station_nm(한국어 역명) 기준으로 환승역을 그룹핑한다.
    /// 대표 로우는 line_num 오름차순 정렬 후 첫 로우로 결정적으로 고정한다 (검색마다 대표값이 바뀌지 않도록).
    func toGroupedStations() -> [SubwayStation] {
        let groupedByName = Dictionary(grouping: self.data, by: { $0.stationNm })
        return groupedByName.values.map { rows in
            let sortedRows = rows.sorted { $0.lineNum < $1.lineNum }
            let representative = sortedRows[0]
            return SubwayStation(
                stationCode: representative.stationCd,
                frCode: representative.frCode,
                koreanName: representative.stationNm,
                japaneseName: representative.stationNmJpn,
                lineNumbers: sortedRows.map { $0.lineNum }
            )
        }
    }
}
