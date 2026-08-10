//
//  TravelPlanDetailUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TravelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol {

    // MARK: - Properties

    private let repository: TravelPlanDetailRepositoryProtocol

    // MARK: - Init

    public init(repository: TravelPlanDetailRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetch(planId: UUID) async throws -> TravelPlanDetail? {
        return try await self.repository.fetch(planId: planId)
    }

    public func add(_ detail: TravelPlanDetail) async throws {
        try await self.repository.add(detail)
    }

    public func removeSpot(planId: UUID, spotId: UUID) async throws {
        try await self.repository.removeSpot(planId: planId, spotId: spotId)
    }

    public func saveEditedSpots(planId: UUID, dayIndex: Int, orderedSpotIds: [UUID]) async throws {
        try await self.repository.saveEditedSpots(planId: planId, dayIndex: dayIndex, orderedSpotIds: orderedSpotIds)
    }
}
