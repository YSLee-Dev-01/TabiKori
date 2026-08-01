//
//  TravelPlanDetailUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelPlanDetailUseCaseProtocol: Sendable {
    func fetch(planId: UUID) async throws -> TravelPlanDetail?
    func add(_ detail: TravelPlanDetail) async throws
}
