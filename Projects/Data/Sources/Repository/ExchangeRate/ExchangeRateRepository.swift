//
//  ExchangeRateRepository.swift
//  Data
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class ExchangeRateRepository: ExchangeRateRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Init

    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Method

    public func fetchExchangeRates() async throws -> [ExchangeRate] {
        let dtos = try await self.networkService.request(
            endPoint: ExchangeRateEndpoint.today,
            responseType: [ExchangeRateDTO].self
        )
        return dtos.compactMap { $0.toEntity() }
    }
}
