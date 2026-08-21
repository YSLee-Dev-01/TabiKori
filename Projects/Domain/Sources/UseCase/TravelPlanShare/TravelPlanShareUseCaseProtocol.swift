//
//  TravelPlanShareUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelPlanShareUseCaseProtocol: Sendable {
    func exportData(
        plan: TravelPlan,
        detail: TravelPlanDetail?,
        shoppingItems: [ShoppingPlanItem],
        toolBarItems: [ToolBarPlanItem]
    ) throws -> Data
    func importPlan(
        from data: Data
    ) throws -> (plan: TravelPlan, detail: TravelPlanDetail, shoppingItems: [ShoppingPlanItem], toolBarItems: [ToolBarPlanItem])
}
