//
//  SubwayStationSearchResponseDTO.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

/// 서울 열린데이터 광장 SearchInfoBySubwayNameService 응답.
/// 성공 시 서비스명(`SearchInfoBySubwayNameService`)이 최상위 키로 오지만,
/// 0건일 때는 그 키 자체가 사라지고 `{"RESULT":{"CODE":"INFO-200", ...}}`만 온다 — 두 형태를 모두 디코딩해야 한다.
struct SubwayStationSearchResponseDTO: Decodable {
    let body: Body?
    let rootResult: ResultDTO?

    struct Body: Decodable {
        let result: ResultDTO
        let row: [RowDTO]?

        enum CodingKeys: String, CodingKey {
            case result = "RESULT"
            case row
        }
    }

    struct ResultDTO: Decodable {
        let code: String
        let message: String

        enum CodingKeys: String, CodingKey {
            case code = "CODE"
            case message = "MESSAGE"
        }
    }

    struct RowDTO: Decodable {
        let stationCd: String
        let stationNm: String
        let lineNum: String
        let frCode: String

        enum CodingKeys: String, CodingKey {
            case stationCd = "STATION_CD"
            case stationNm = "STATION_NM"
            case lineNum = "LINE_NUM"
            case frCode = "FR_CODE"
        }
    }

    private enum RootKey: String, CodingKey {
        case service = "SearchInfoBySubwayNameService"
        case result = "RESULT"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKey.self)
        if container.contains(.service) {
            self.body = try container.decode(Body.self, forKey: .service)
            self.rootResult = nil
        } else {
            self.body = nil
            self.rootResult = try container.decode(ResultDTO.self, forKey: .result)
        }
    }
}

// MARK: - Mapping

extension SubwayStationSearchResponseDTO {
    private static let successCode = "INFO-000"
    private static let noDataCode = "INFO-200"

    /// 실재 확인 결과. 성공 코드 + row 존재 시 true, "데이터 없음"(INFO-200)은 false, 그 외 코드는 에러로 취급한다.
    func toExistsResult() throws -> Bool {
        if let body {
            if body.result.code == Self.successCode, let row = body.row, row.isEmpty == false {
                return true
            }
            AppLogger.network.log(.error, "❌ 지하철역 검색 실패: \(body.result.code) \(body.result.message)")
            throw TabiError.apiFailed(code: body.result.code, message: body.result.message)
        }

        guard let rootResult else {
            throw TabiError.decodingFailed(message: "SubwayStationSearchResponseDTO 응답 형식을 인식할 수 없음")
        }
        if rootResult.code == Self.noDataCode {
            return false
        }
        AppLogger.network.log(.error, "❌ 지하철역 검색 실패: \(rootResult.code) \(rootResult.message)")
        throw TabiError.apiFailed(code: rootResult.code, message: rootResult.message)
    }
}
