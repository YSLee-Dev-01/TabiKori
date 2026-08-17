//
//  TravelItemUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelItemUseCaseProtocol: Sendable {
    func fetchMasterItems() async throws -> [TravelItem]
    func fetchSavedItems(planId: UUID) async throws -> [TravelPlanItem]
    func save(planId: UUID, items: [TravelItem]) async throws
    func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws
}
