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
}
