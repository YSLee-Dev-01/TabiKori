//
//  TestExchangeRateUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestExchangeRateUseCase: ExchangeRateUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var krwToJPYRate: Double = 0.1073

    // MARK: - Method

    public func fetchKRWToJPYRate() async throws -> Double {
        return self.krwToJPYRate
    }
}
