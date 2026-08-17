//
//  TravelPlanRepository.swift
//  Data
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core
import Domain

public final class TravelPlanRepository: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Init

    public init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - TravelPlanRepositoryProtocol

extension TravelPlanRepository: TravelPlanRepositoryProtocol {
    public func fetch() async throws -> [TravelPlan] {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanModel>(
                sortBy: [SortDescriptor(\.startDate, order: .forward)]
            )
            return try context.fetch(descriptor).compactMap(\.toDomain)
        } catch {
            AppLogger.core.log(.error, "일정 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func add(_ plan: TravelPlan) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let model = TravelPlanModel(plan: plan)
            context.insert(model)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func update(_ plan: TravelPlan) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let planId = plan.id
            let descriptor = FetchDescriptor<TravelPlanModel>(
                predicate: #Predicate { $0.id == planId }
            )
            guard let model = try context.fetch(descriptor).first else {
                AppLogger.core.log(.error, "일정 수정 실패: 대상 플랜을 찾을 수 없음 (planId: \(planId))")
                throw TabiError.persistenceFailed(message: "대상 플랜을 찾을 수 없습니다")
            }

            model.title = plan.title
            model.regionRaw = plan.region.rawValue
            model.customRegionText = plan.customRegionText
            model.customEmoji = plan.customEmoji
            model.startDate = plan.startDate
            model.endDate = plan.endDate

            try context.save()
        } catch let error as TabiError {
            throw error
        } catch {
            AppLogger.core.log(.error, "일정 수정 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func remove(planId: UUID) async throws {
        do {
            let context = ModelContext(self.modelContainer)

            let planDescriptor = FetchDescriptor<TravelPlanModel>(
                predicate: #Predicate { $0.id == planId }
            )
            if let planModel = try context.fetch(planDescriptor).first {
                context.delete(planModel)
            }

            let detailDescriptor = FetchDescriptor<TravelPlanDetailModel>(
                predicate: #Predicate { $0.planId == planId }
            )
            if let detailModel = try context.fetch(detailDescriptor).first {
                context.delete(detailModel)
            }

            let spotDescriptor = FetchDescriptor<TravelPlanDetailSpotModel>(
                predicate: #Predicate { $0.planId == planId }
            )
            for spotModel in try context.fetch(spotDescriptor) {
                context.delete(spotModel)
            }

            let itemDescriptor = FetchDescriptor<TravelPlanItemModel>(
                predicate: #Predicate { $0.planId == planId }
            )
            for itemModel in try context.fetch(itemDescriptor) {
                context.delete(itemModel)
            }

            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func removeAll() async throws {
        do {
            let context = ModelContext(self.modelContainer)
            try context.delete(model: TravelPlanModel.self)
            try context.delete(model: TravelPlanDetailModel.self)
            try context.delete(model: TravelPlanDetailSpotModel.self)
            try context.delete(model: TravelPlanItemModel.self)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "일정 전체 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }
}
