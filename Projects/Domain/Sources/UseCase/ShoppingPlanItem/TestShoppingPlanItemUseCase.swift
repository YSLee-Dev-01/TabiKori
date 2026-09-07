//
//  TestShoppingPlanItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestShoppingPlanItemUseCase: ShoppingPlanItemUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var savedItems: [ShoppingPlanItem] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchSavedItems(planId: UUID) async throws -> [ShoppingPlanItem] {
        return self.savedItems.filter { $0.planId == planId }
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        guard let index = self.savedItems.firstIndex(where: { $0.planId == planId && $0.id == itemId }) else { return }
        self.savedItems[index].isChecked = isChecked
    }

    public func replace(planId: UUID, items: [ShoppingPlanItem]) async throws {
        self.savedItems.removeAll { $0.planId == planId }
        self.savedItems.append(contentsOf: items)
    }
}
