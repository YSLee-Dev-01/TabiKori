//
//  ExchangeRateDTO.swift
//  Data
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct ExchangeRateDTO: Decodable {
    let result: Int
    let curUnit: String?
    let curNm: String?
    let dealBasR: String?

    enum CodingKeys: String, CodingKey {
        case result
        case curUnit = "cur_unit"
        case curNm = "cur_nm"
        case dealBasR = "deal_bas_r"
    }
}

// MARK: - Mapping

extension ExchangeRateDTO {
    func toEntity() -> ExchangeRate? {
        guard self.result == 1 else {
            AppLogger.network.log(.error, "❌ 환율 조회 실패: result \(self.result)")
            return nil
        }

        guard let curUnit, let curNm, let dealBasR,
              let baseRate = Double(dealBasR.replacingOccurrences(of: ",", with: "")) else {
            AppLogger.network.log(.error, "❌ 환율 응답 파싱 실패: \(self)")
            return nil
        }

        let (currencyCode, unitScale) = Self.parseCurrencyUnit(curUnit)
        return ExchangeRate(
            currencyCode: currencyCode,
            currencyName: curNm,
            unitScale: unitScale,
            baseRate: baseRate
        )
    }
}

private extension ExchangeRateDTO {
    static func parseCurrencyUnit(_ raw: String) -> (code: String, scale: Int) {
        guard let openParenIndex = raw.firstIndex(of: "("),
              let closeParenIndex = raw.firstIndex(of: ")"),
              openParenIndex < closeParenIndex else {
            return (raw, 1)
        }

        let code = String(raw[raw.startIndex..<openParenIndex])
        let scaleText = String(raw[raw.index(after: openParenIndex)..<closeParenIndex])
        return (code, Int(scaleText) ?? 1)
    }
}
