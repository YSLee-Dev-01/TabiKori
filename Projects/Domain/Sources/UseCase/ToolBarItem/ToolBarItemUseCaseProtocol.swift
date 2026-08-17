//
//  ToolBarItemUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol ToolBarItemUseCaseProtocol: Sendable {
    func fetchMasterItems() async throws -> [ToolBarItem]
    func fetchSavedItems(planId: UUID) async throws -> [ToolBarPlanItem]
    func save(planId: UUID, items: [ToolBarItem]) async throws
    func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws
}
