//
//  TravelPlanUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelPlanUseCaseProtocol: Sendable {
    func fetch() async throws -> [TravelPlan]
    func add(_ plan: TravelPlan) async throws
    func remove(planId: UUID) async throws
}
