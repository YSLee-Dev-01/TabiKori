//
//  TestTravelPlanDetailUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTravelPlanDetailUseCase: TravelPlanDetailUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var details: [TravelPlanDetail] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetch(planId: UUID) async throws -> TravelPlanDetail? {
        return self.details.first(where: { $0.planId == planId })
    }

    public func add(_ detail: TravelPlanDetail) async throws {
        self.details.append(detail)
    }

    public func removeSpot(planId: UUID, spotId: UUID) async throws {
        guard let index = self.details.firstIndex(where: { $0.planId == planId }) else { return }
        let detail = self.details[index]
        self.details[index] = TravelPlanDetail(
            planId: detail.planId,
            spots: detail.spots.filter { $0.id != spotId }
        )
    }

    public func removeSpots(planId: UUID, fromDayIndex: Int) async throws {
        guard let index = self.details.firstIndex(where: { $0.planId == planId }) else { return }
        let detail = self.details[index]
        self.details[index] = TravelPlanDetail(
            planId: detail.planId,
            spots: detail.spots.filter { $0.dayIndex < fromDayIndex }
        )
    }

    public func saveEditedSpots(planId: UUID, dayIndex: Int, orderedSpotIds: [UUID]) async throws {
        guard let index = self.details.firstIndex(where: { $0.planId == planId }) else { return }
        let detail = self.details[index]
        let otherDaySpots = detail.spots.filter { $0.dayIndex != dayIndex }
        let daySpotsById = Dictionary(uniqueKeysWithValues: detail.spots.filter { $0.dayIndex == dayIndex }.map { ($0.id, $0) })
        let updatedDaySpots: [TravelPlanDetailSpot] = orderedSpotIds.enumerated().compactMap { newOrder, spotId in
            guard let spot = daySpotsById[spotId] else { return nil }
            return TravelPlanDetailSpot(
                id: spot.id,
                dayIndex: spot.dayIndex,
                order: newOrder,
                category: spot.category,
                title: spot.title,
                subtitle: spot.subtitle,
                startTime: spot.startTime,
                durationMinutes: spot.durationMinutes,
                contentId: spot.contentId,
                coordinate: spot.coordinate,
                thumbnailURLString: spot.thumbnailURLString,
                isCustom: spot.isCustom,
                address: spot.address
            )
        }
        self.details[index] = TravelPlanDetail(
            planId: detail.planId,
            spots: otherDaySpots + updatedDaySpots
        )
    }

    public func updateSpotTime(planId: UUID, spotId: UUID, startTime: Date?, durationMinutes: Int?) async throws {
        guard let detailIndex = self.details.firstIndex(where: { $0.planId == planId }) else { return }
        let detail = self.details[detailIndex]
        guard let spotIndex = detail.spots.firstIndex(where: { $0.id == spotId }) else { return }
        let spot = detail.spots[spotIndex]
        var updatedSpots = detail.spots
        updatedSpots[spotIndex] = TravelPlanDetailSpot(
            id: spot.id,
            dayIndex: spot.dayIndex,
            order: spot.order,
            category: spot.category,
            title: spot.title,
            subtitle: spot.subtitle,
            startTime: startTime,
            durationMinutes: durationMinutes,
            contentId: spot.contentId,
            coordinate: spot.coordinate,
            thumbnailURLString: spot.thumbnailURLString,
            isCustom: spot.isCustom,
            isStation: spot.isStation,
            address: spot.address
        )
        self.details[detailIndex] = TravelPlanDetail(planId: detail.planId, spots: updatedSpots)
    }
}
