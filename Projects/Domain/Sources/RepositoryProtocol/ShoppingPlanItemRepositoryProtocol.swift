//
//  ShoppingPlanItemRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol ShoppingPlanItemRepositoryProtocol: Sendable {
    func fetch(planId: UUID) async throws -> [ShoppingPlanItem]
    func replace(planId: UUID, items: [ShoppingPlanItem]) async throws
    func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws
}
