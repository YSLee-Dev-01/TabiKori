//
//  ExchangeRateRepository.swift
//  Data
//
//  Created by 이윤수 on 7/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class ExchangeRateRepository: ExchangeRateRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchExchangeRates() async throws -> [ExchangeRate] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/exchangeRates")
        let snapshot = try await databaseReference.getData()

        guard let value = snapshot.value as? [String: Any],
              let updatedAtMillis = (value["updatedAt"] as? NSNumber)?.doubleValue,
              let rates = value["rates"] as? [String: Any],
              let jpy = rates[ExchangeRate.jpyCurrencyCode] as? [String: Any],
              let baseRate = (jpy["baseRate"] as? NSNumber)?.doubleValue,
              let unitScale = (jpy["unitScale"] as? NSNumber)?.intValue else {
            AppLogger.network.log(.error, "환율 정보 조회 실패: TabiKori/exchangeRates 데이터 없음")
            throw TabiError.dataNotFound
        }

        let updatedAt = Date(timeIntervalSince1970: updatedAtMillis / 1000)

        return [
            ExchangeRate(
                currencyCode: ExchangeRate.jpyCurrencyCode,
                currencyName: "일본 옌",
                unitScale: unitScale,
                baseRate: baseRate,
                updatedAt: updatedAt
            )
        ]
    }
}
