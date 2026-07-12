//
//  TouristSpotImageDTO.swift
//  Data
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct TouristSpotImageResponseDTO: Decodable {
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
        let item: [TouristSpotImageItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([TouristSpotImageItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct TouristSpotImageItemDTO: Decodable {
    let originimgurl: String
    let smallimageurl: String
    let imgname: String
}

// MARK: - Mapping

extension TouristSpotImageResponseDTO {
    func toEntities() throws -> [TouristSpotImage] {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 관광지 이미지 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        return self.response.body.items.item.map { $0.toEntity() }
    }
}

private extension TouristSpotImageItemDTO {
    func toEntity() -> TouristSpotImage {
        return TouristSpotImage(
            imageURLString: self.originimgurl,
            thumbnailURLString: self.smallimageurl,
            name: self.imgname
        )
    }
}
