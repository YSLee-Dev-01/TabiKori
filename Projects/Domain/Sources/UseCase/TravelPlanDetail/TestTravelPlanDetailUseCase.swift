//
//  TestTravelPlanDetailUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTravelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var details: [TravelPlanDetail] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetch(planId: UUID) async throws -> TravelPlanDetail? {
        return self.details.first(where: { $0.planId == planId })
    }

    public func add(_ detail: TravelPlanDetail) async throws {
        self.details.append(detail)
    }

    public func removeSpot(planId: UUID, spotId: UUID) async throws {
        guard let index = self.details.firstIndex(where: { $0.planId == planId }) else { return }
        let detail = self.details[index]
        self.details[index] = TravelPlanDetail(
            planId: detail.planId,
            spots: detail.spots.filter { $0.id != spotId }
        )
    }
}
