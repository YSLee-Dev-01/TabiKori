//
//  TravelPlanItemRepository.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core
import Domain

public final class TravelPlanItemRepository: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Init

    public init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - TravelPlanItemRepositoryProtocol

extension TravelPlanItemRepository: TravelPlanItemRepositoryProtocol {
    public func fetch(planId: UUID) async throws -> [TravelPlanItem] {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanItemModel>(
                predicate: #Predicate { $0.planId == planId },
                sortBy: [SortDescriptor(\.order)]
            )
            return try context.fetch(descriptor).map(\.toDomain)
        } catch {
            AppLogger.core.log(.error, "준비물 저장 목록 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func replace(planId: UUID, items: [TravelPlanItem]) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanItemModel>(
                predicate: #Predicate { $0.planId == planId }
            )
            for model in try context.fetch(descriptor) {
                context.delete(model)
            }
            for item in items {
                context.insert(TravelPlanItemModel(item: item))
            }
            try context.save()
        } catch {
            AppLogger.core.log(.error, "준비물 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<TravelPlanItemModel>(
                predicate: #Predicate { $0.planId == planId && $0.id == itemId }
            )
            guard let model = try context.fetch(descriptor).first else {
                AppLogger.core.log(.error, "준비물 체크 상태 변경 실패: 대상 항목을 찾을 수 없음 (planId: \(planId), itemId: \(itemId))")
                return
            }
            model.isChecked = isChecked
            try context.save()
        } catch {
            AppLogger.core.log(.error, "준비물 체크 상태 변경 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }
}
