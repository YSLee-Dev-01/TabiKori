//
//  ShoppingPlanItemUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol ShoppingPlanItemUseCaseProtocol: Sendable {
    func fetchSavedItems(planId: UUID) async throws -> [ShoppingPlanItem]
    func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws
    func replace(planId: UUID, items: [ShoppingPlanItem]) async throws
}
