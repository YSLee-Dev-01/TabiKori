//
//  TestTravelPlanUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTravelPlanUseCase: TravelPlanUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var plans: [TravelPlan] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetch() async throws -> [TravelPlan] {
        return self.plans
    }

    public func add(_ plan: TravelPlan) async throws {
        self.plans.append(plan)
    }
}
