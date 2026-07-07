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
    private let userDefault: TabiUserDefaultProtocol
    private let calendar: Calendar

    // MARK: - Init

    public init(
        networkService: NetworkServiceProtocol = NetworkService(),
        userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared,
        calendar: Calendar = .current
    ) {
        self.networkService = networkService
        self.userDefault = userDefault
        self.calendar = calendar
    }

    // MARK: - Method

    public func fetchExchangeRates() async throws -> [ExchangeRate] {
        if let cachedRates = self.cachedExchangeRates() {
            return cachedRates
        }

        let dtos = try await self.networkService.request(
            endPoint: ExchangeRateEndpoint.today,
            responseType: [ExchangeRateDTO].self
        )
        let rates = dtos.compactMap { $0.toEntity() }
        self.cacheExchangeRates(rates)
        return rates
    }
}

// MARK: - Method

private extension ExchangeRateRepository {
    func cachedExchangeRates() -> [ExchangeRate]? {
        guard let fetchedAt: Date = self.userDefault.get(forKey: .exchangeRateFetchedAt),
              self.isSameTradingDay(fetchedAt, Date()),
              let data: Data = self.userDefault.get(forKey: .exchangeRates),
              let rates = try? JSONDecoder().decode([ExchangeRate].self, from: data) else {
            return nil
        }
        return rates
    }

    func cacheExchangeRates(_ rates: [ExchangeRate]) {
        guard let data = try? JSONEncoder().encode(rates) else { return }
        self.userDefault.set(data, forKey: .exchangeRates)
        self.userDefault.set(Date(), forKey: .exchangeRateFetchedAt)
    }

    func isSameTradingDay(_ lhs: Date, _ rhs: Date) -> Bool {
        return self.tradingDay(for: lhs) == self.tradingDay(for: rhs)
    }

    /// 환율 고시가 정오(12시)에 갱신되는 것을 반영해 하루 경계를 정오로 이동시킨 기준일을 계산
    func tradingDay(for date: Date) -> Date {
        let shiftedDate = self.calendar.date(byAdding: .hour, value: -12, to: date) ?? date
        return self.calendar.startOfDay(for: shiftedDate)
    }
}
