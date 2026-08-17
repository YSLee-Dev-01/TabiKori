//
//  TestTravelItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTravelItemUseCase: TravelItemUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var masterItems: [TravelItem] = []
    public var savedItems: [TravelPlanItem] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchMasterItems() async throws -> [TravelItem] {
        return self.masterItems
    }

    public func fetchSavedItems(planId: UUID) async throws -> [TravelPlanItem] {
        return self.savedItems.filter { $0.planId == planId }
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
        self.savedItems.removeAll { $0.planId == planId }
        self.savedItems.append(contentsOf: planItems)
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        guard let index = self.savedItems.firstIndex(where: { $0.planId == planId && $0.id == itemId }) else { return }
        self.savedItems[index].isChecked = isChecked
    }
}
