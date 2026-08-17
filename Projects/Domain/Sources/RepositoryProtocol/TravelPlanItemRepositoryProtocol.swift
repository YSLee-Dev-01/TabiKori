//
//  TravelPlanItemRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelPlanItemRepositoryProtocol: Sendable {
    func fetch(planId: UUID) async throws -> [TravelPlanItem]
    func replace(planId: UUID, items: [TravelPlanItem]) async throws
    func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws
}
