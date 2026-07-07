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
}

// MARK: - Mapping

extension TouristSpotResponseDTO {
    func toEntities() -> [TouristSpot] {
        switch self.response.header.resultCode {
        case "0000":
            return self.response.body.items.item.compactMap { $0.toEntity() }

        default:
            AppLogger.network.log(.error, "❌ 관광지 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            return []
        }
    }
}

private extension TouristSpotItemDTO {
    func toEntity() -> TouristSpot? {
        guard let contenttypeid, let contentType = TouristSpotContentType(apiCode: contenttypeid) else {
            AppLogger.network.log(.error, "❌ 알 수 없는 contenttypeid: \(self.contenttypeid ?? "nil")")
            return nil
        }

        return TouristSpot(
            id: self.contentid,
            title: self.title,
            thumbnailURL: self.firstimage,
            distanceMeters: self.dist?.toDouble(),
            contentType: contentType
        )
    }
}

private extension TouristSpotContentType {
    init?(apiCode: String) {
        switch apiCode {
        case "12": self = .touristSpot
        case "14": self = .culturalFacility
        case "15": self = .festival
        case "28": self = .leisure
        case "32": self = .accommodation
        case "38": self = .shopping
        case "39": self = .restaurant
        default: return nil
        }
    }
}
