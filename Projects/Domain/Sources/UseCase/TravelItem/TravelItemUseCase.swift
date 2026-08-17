//
//  TravelItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TravelItemUseCase: TravelItemUseCaseProtocol {

    // MARK: - Properties

    private let travelItemRepository: TravelItemRepositoryProtocol
    private let travelPlanItemRepository: TravelPlanItemRepositoryProtocol

    // MARK: - Init

    public init(
        travelItemRepository: TravelItemRepositoryProtocol,
        travelPlanItemRepository: TravelPlanItemRepositoryProtocol
    ) {
        self.travelItemRepository = travelItemRepository
        self.travelPlanItemRepository = travelPlanItemRepository
    }

    // MARK: - Method

    public func fetchMasterItems() async throws -> [TravelItem] {
        return try await self.travelItemRepository.fetchMasterItems()
    }

    public func fetchSavedItems(planId: UUID) async throws -> [TravelPlanItem] {
        return try await self.travelPlanItemRepository.fetch(planId: planId)
    }

    public func save(planId: UUID, items: [TravelItem]) async throws {
        let planItems = items.map { item in
            TravelPlanItem(
                id: UUID(),
                planId: planId,
                order: item.order,
                title: item.title,
                note: item.note,
                isChecked: false
            )
        }
        try await self.travelPlanItemRepository.replace(planId: planId, items: planItems)
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        try await self.travelPlanItemRepository.updateChecked(planId: planId, itemId: itemId, isChecked: isChecked)
    }
}
