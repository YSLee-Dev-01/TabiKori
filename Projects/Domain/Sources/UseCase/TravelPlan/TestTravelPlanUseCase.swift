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

    public func update(_ plan: TravelPlan) async throws {
        guard let index = self.plans.firstIndex(where: { $0.id == plan.id }) else { return }
        self.plans[index] = plan
    }

    public func remove(planId: UUID) async throws {
        self.plans.removeAll { $0.id == planId }
    }
}
