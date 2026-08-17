//
//  ToolBarItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class ToolBarItemUseCase: ToolBarItemUseCaseProtocol {

    // MARK: - Properties

    private let toolBarItemRepository: ToolBarItemRepositoryProtocol
    private let toolBarPlanItemRepository: ToolBarPlanItemRepositoryProtocol

    // MARK: - Init

    public init(
        toolBarItemRepository: ToolBarItemRepositoryProtocol,
        toolBarPlanItemRepository: ToolBarPlanItemRepositoryProtocol
    ) {
        self.toolBarItemRepository = toolBarItemRepository
        self.toolBarPlanItemRepository = toolBarPlanItemRepository
    }

    // MARK: - Method

    public func fetchMasterItems() async throws -> [ToolBarItem] {
        return try await self.toolBarItemRepository.fetchMasterItems()
    }

    public func fetchSavedItems(planId: UUID) async throws -> [ToolBarPlanItem] {
        return try await self.toolBarPlanItemRepository.fetch(planId: planId)
    }

    public func save(planId: UUID, items: [ToolBarItem]) async throws {
        let planItems = items.map { item in
            ToolBarPlanItem(
                id: UUID(),
                planId: planId,
                order: item.order,
                title: item.title,
                note: item.note,
                isChecked: false
            )
        }
        try await self.toolBarPlanItemRepository.replace(planId: planId, items: planItems)
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        try await self.toolBarPlanItemRepository.updateChecked(planId: planId, itemId: itemId, isChecked: isChecked)
    }
}
