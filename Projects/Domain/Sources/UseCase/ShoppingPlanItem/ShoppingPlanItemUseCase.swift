//
//  ShoppingPlanItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class ShoppingPlanItemUseCase: ShoppingPlanItemUseCaseProtocol {

    // MARK: - Properties

    private let shoppingPlanItemRepository: ShoppingPlanItemRepositoryProtocol

    // MARK: - Init

    public init(shoppingPlanItemRepository: ShoppingPlanItemRepositoryProtocol) {
        self.shoppingPlanItemRepository = shoppingPlanItemRepository
    }

    // MARK: - Method

    public func fetchSavedItems(planId: UUID) async throws -> [ShoppingPlanItem] {
        return try await self.shoppingPlanItemRepository.fetch(planId: planId)
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        try await self.shoppingPlanItemRepository.updateChecked(planId: planId, itemId: itemId, isChecked: isChecked)
    }

    public func replace(planId: UUID, items: [ShoppingPlanItem]) async throws {
        try await self.shoppingPlanItemRepository.replace(planId: planId, items: items)
    }
}
