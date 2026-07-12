//
//  TouristSpotDetailDTO.swift
//  Data
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct TouristSpotDetailResponseDTO: Decodable {
    let response: ResponseBody

    struct ResponseBody: Decodable {
        let header: Header
        let body: Body
    }

    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }

    struct Body: Decodable {
        let items: Items
    }

    struct Items: Decodable {
        let item: [TouristSpotDetailItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([TouristSpotDetailItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct TouristSpotDetailItemDTO: Decodable {
    let contentid: String
    let contenttypeid: String
    let title: String
    let tel: String?
    let homepage: String?
    let firstimage: String?
    let addr1: String?
    let addr2: String?
    let mapx: String?
    let mapy: String?
    let overview: String?
}

// MARK: - Mapping

extension TouristSpotDetailResponseDTO {
    func toEntity() throws -> TouristSpotDetail {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 관광지 상세 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        guard let item = self.response.body.items.item.first else {
            AppLogger.network.log(.error, "❌ 관광지 상세 데이터 없음")
            throw TabiError.apiFailed(code: "EMPTY", message: "No detail item found")
        }
        return try item.toEntity()
    }
}

private extension TouristSpotDetailItemDTO {
    func toEntity() throws -> TouristSpotDetail {
        guard let contentType = CategoryType(apiCode: self.contenttypeid) else {
            AppLogger.network.log(.error, "❌ 알 수 없는 contenttypeid: \(self.contenttypeid)")
            throw TabiError.apiFailed(code: "UNKNOWN_TYPE", message: "Unknown contenttypeid: \(self.contenttypeid)")
        }

        let coordinate = Coordinate(
            latitude: self.mapy?.toDouble() ?? 0,
            longitude: self.mapx?.toDouble() ?? 0
        )

        let addressParts = [self.addr1, self.addr2].compactMap { $0?.isEmpty == false ? $0 : nil }
        let address = addressParts.joined(separator: " ")

        let tel = self.tel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let homepage = self.homepage?.trimmingCharacters(in: .whitespacesAndNewlines)

        return TouristSpotDetail(
            id: self.contentid,
            title: self.title,
            contentType: contentType,
            tel: tel?.isEmpty == false ? tel : nil,
            homepageURLString: homepage?.isEmpty == false ? homepage : nil,
            imageURLString: self.firstimage,
            address: address,
            coordinate: coordinate,
            overview: self.overview
        )
    }
}
