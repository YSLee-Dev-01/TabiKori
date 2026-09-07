//
//  LDongRegionDTO.swift
//  Data
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct LDongRegionResponseDTO: Decodable {
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
        let item: [LDongRegionItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([LDongRegionItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct LDongRegionItemDTO: Decodable {
    let code: String
    let name: String
}

// MARK: - Mapping

extension LDongRegionResponseDTO {
    func toEntities() throws -> [LDongRegion] {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 법정동코드 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        return self.response.body?.items.item.map { $0.toEntity() } ?? []
    }
}

private extension LDongRegionItemDTO {
    func toEntity() -> LDongRegion {
        return LDongRegion(code: self.code, name: self.name)
    }
}
