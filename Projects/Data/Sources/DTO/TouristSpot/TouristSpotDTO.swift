//
//  TouristSpotDTO.swift
//  Data
//
//  Created by 이윤수 on 7/7/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct TouristSpotResponseDTO: Decodable {
    let response: ResponseBody

    struct ResponseBody: Decodable {
        let header: Header
        let body: Body?
    }

    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }

    struct Body: Decodable {
        let items: Items
    }

    struct Items: Decodable {
        let item: [TouristSpotItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([TouristSpotItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct TouristSpotItemDTO: Decodable {
    let contentid: String
    let contenttypeid: String?
    let title: String
    let firstimage: String?
    let dist: String?
    let mapx: String?
    let mapy: String?
    let addr1: String?
    let addr2: String?
}

// MARK: - Mapping

extension TouristSpotResponseDTO {
    func toEntities() throws -> [TouristSpot] {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 관광지 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        return self.response.body?.items.item.compactMap { $0.toEntity() } ?? []
    }
}

private extension TouristSpotItemDTO {
    func toEntity() -> TouristSpot? {
        guard let contenttypeid, let contentType = CategoryType(apiCode: contenttypeid) else {
            AppLogger.network.log(.error, "❌ 알 수 없는 contenttypeid: \(self.contenttypeid ?? "nil")")
            return nil
        }

        let latitude = self.mapy?.toDouble()
        let longitude = self.mapx?.toDouble()
        if latitude == nil || longitude == nil {
            AppLogger.network.log(.error, "⚠️ 좌표 파싱 실패 (contentid: \(self.contentid)): mapx=\(self.mapx ?? "nil"), mapy=\(self.mapy ?? "nil")")
        }

        let addressParts = [self.addr1, self.addr2].compactMap { $0?.isEmpty == false ? $0 : nil }
        let address = addressParts.joined(separator: " ").replacingBRWithNewline

        return TouristSpot(
            id: self.contentid,
            title: self.title,
            thumbnailURLString: self.firstimage,
            distanceMeters: self.dist?.toDouble(),
            contentType: contentType,
            coordinate: Coordinate(latitude: latitude ?? Coordinate.zero.latitude, longitude: longitude ?? Coordinate.zero.longitude),
            address: address.isEmpty == false ? address : nil
        )
    }
}
