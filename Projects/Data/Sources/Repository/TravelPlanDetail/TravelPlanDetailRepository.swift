//
//  TravelPlanDetailRepository.swift
//  Data
//
//  Created by 이윤수 on 8/1/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core
import Domain

public final class TravelPlanDetailRepository: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Init

    public init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - TravelPlanDetailRepositoryProtocol

extension TravelPlanDetailRepository: TravelPlanDetailRepositoryProtocol {
    public func fetch(planId: UUID) async throws -> TravelPlanDetail? {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanDetailModel>(
                predicate: #Predicate { $0.planId == planId }
            )
            guard let model = try context.fetch(descriptor).first else { return nil }

            let spotDescriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId },
                sortBy: [SortDescriptor(\.dayIndex), SortDescriptor(\.order)]
            )
            let spots = try context.fetch(spotDescriptor).compactMap(\.toDomain)
            return model.toDomain(spots: spots)
        } catch {
            AppLogger.core.log(.error, "일정 상세 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func add(_ detail: TravelPlanDetail) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let model = TravelPlanDetailModel(detail: detail)
            context.insert(model)
            for spot in detail.spots {
                context.insert(TravelPlanDetailSpotModel(spot: spot, planId: detail.planId))
            }
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 상세 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func removeSpot(planId: UUID, spotId: UUID) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId && $0.id == spotId }
            )
            guard let model = try context.fetch(descriptor).first else { return }
            context.delete(model)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 상세 스팟 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func removeSpots(planId: UUID, fromDayIndex: Int) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId && $0.dayIndex >= fromDayIndex }
            )
            for model in try context.fetch(descriptor) {
                context.delete(model)
            }
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 상세 스팟 일괄 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func saveEditedSpots(planId: UUID, dayIndex: Int, orderedSpotIds: [UUID]) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId && $0.dayIndex == dayIndex }
            )
            let models = try context.fetch(descriptor)
            let modelsById = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })

            for model in models where !orderedSpotIds.contains(model.id) {
                context.delete(model)
            }

            for (newOrder, spotId) in orderedSpotIds.enumerated() {
                guard let model = modelsById[spotId] else { continue }
                model.order = newOrder
            }

            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 상세 스팟 편집 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func updateSpotTime(planId: UUID, spotId: UUID, startTime: Date, durationMinutes: Int) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId && $0.id == spotId }
            )
            guard let model = try context.fetch(descriptor).first else {
                AppLogger.core.log(.error, "일정 상세 시간 수정 실패: 대상 스팟을 찾을 수 없음 (planId: \(planId), spotId: \(spotId))")
                return
            }
            model.startTime = startTime
            model.durationMinutes = durationMinutes
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 상세 시간 수정 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }
}
