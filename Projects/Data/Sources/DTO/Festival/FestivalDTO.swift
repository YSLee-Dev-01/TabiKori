//
//  FestivalDTO.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct FestivalResponseDTO: Decodable {
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
        let item: [FestivalItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([FestivalItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct FestivalItemDTO: Decodable {
    let contentid: String
    let contenttypeid: String?
    let title: String
    let firstimage: String?
    let mapx: String?
    let mapy: String?
    let eventstartdate: String?
    let eventenddate: String?
}

// MARK: - Mapping

extension FestivalResponseDTO {
    func toEntities() throws -> [Festival] {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 행사 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        return self.response.body?.items.item.compactMap { $0.toEntity() } ?? []
    }
}

private extension FestivalItemDTO {
    func toEntity() -> Festival? {
        guard let eventstartdate, let eventStartDate = eventstartdate.toFestivalDate() else {
            AppLogger.network.log(.error, "❌ eventstartdate 파싱 실패 (contentid: \(self.contentid)): \(self.eventstartdate ?? "nil")")
            return nil
        }
        let eventEndDate = self.eventenddate?.toFestivalDate()

        let contentType: CategoryType
        if let contenttypeid {
            guard let resolved = CategoryType(apiCode: contenttypeid) else {
                AppLogger.network.log(.error, "❌ 알 수 없는 contenttypeid: \(contenttypeid)")
                return nil
            }
            contentType = resolved
        } else {
            contentType = .festival
        }

        let latitude = self.mapy?.toDouble()
        let longitude = self.mapx?.toDouble()
        if latitude == nil || longitude == nil {
            AppLogger.network.log(.error, "⚠️ 좌표 파싱 실패 (contentid: \(self.contentid)): mapx=\(self.mapx ?? "nil"), mapy=\(self.mapy ?? "nil")")
        }

        let touristSpot = TouristSpot(
            id: self.contentid,
            title: self.title,
            thumbnailURLString: self.firstimage,
            distanceMeters: nil,
            contentType: contentType,
            coordinate: Coordinate(latitude: latitude ?? Coordinate.zero.latitude, longitude: longitude ?? Coordinate.zero.longitude)
        )

        return Festival(touristSpot: touristSpot, startDate: eventStartDate, endDate: eventEndDate)
    }
}
