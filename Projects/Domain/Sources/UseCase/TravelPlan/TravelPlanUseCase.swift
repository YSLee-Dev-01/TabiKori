//
//  TravelPlanUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TravelPlanUseCase: TravelPlanUseCaseProtocol {

    // MARK: - Properties

    private let repository: TravelPlanRepositoryProtocol

    // MARK: - Init

    public init(repository: TravelPlanRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetch() async throws -> [TravelPlan] {
        return try await self.repository.fetch()
    }

    public func add(_ plan: TravelPlan) async throws {
        try await self.repository.add(plan)
    }
}
