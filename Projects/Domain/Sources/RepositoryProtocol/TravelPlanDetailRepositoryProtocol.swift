//
//  TravelPlanDetailRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TravelPlanDetailRepositoryProtocol: Sendable {
    func fetch(planId: UUID) async throws -> TravelPlanDetail?
    func add(_ detail: TravelPlanDetail) async throws
    func removeSpot(planId: UUID, spotId: UUID) async throws
    func removeSpots(planId: UUID, fromDayIndex: Int) async throws
    func saveEditedSpots(planId: UUID, dayIndex: Int, orderedSpotIds: [UUID]) async throws
}
