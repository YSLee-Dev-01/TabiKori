//
//  ExchangeRateUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class ExchangeRateUseCase: ExchangeRateUseCaseProtocol {

    // MARK: - Properties

    private let repository: ExchangeRateRepositoryProtocol

    // MARK: - Init

    public init(repository: ExchangeRateRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchKRWToJPYRate() async throws -> KRWToJPYRate {
        let rates = try await self.repository.fetchExchangeRates()

        guard let jpy = rates.first(where: { $0.currencyCode == ExchangeRate.jpyCurrencyCode }) else {
            throw TabiError.dataNotFound
        }
        guard jpy.baseRate > 0 else {
            throw TabiError.dataNotFound
        }

        return KRWToJPYRate(rate: Double(jpy.unitScale) / jpy.baseRate, updatedAt: jpy.updatedAt)
    }
}
