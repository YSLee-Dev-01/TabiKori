//
//  ExchangeRateRepository.swift
//  Data
//
//  Created by 이윤수 on 7/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

import FirebaseDatabase

public final class ExchangeRateRepository: ExchangeRateRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchExchangeRates() async throws -> [ExchangeRate] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/exchangeRates/rates/JPY")
        let snapshot = try await databaseReference.getData()

        guard let value = snapshot.value as? [String: Any],
              let baseRate = (value["baseRate"] as? NSNumber)?.doubleValue,
              let unitScale = (value["unitScale"] as? NSNumber)?.intValue else {
            throw TabiError.dataNotFound
        }

        return [ExchangeRate(currencyCode: "JPY", currencyName: "일본 옌", unitScale: unitScale, baseRate: baseRate)]
    }
}
