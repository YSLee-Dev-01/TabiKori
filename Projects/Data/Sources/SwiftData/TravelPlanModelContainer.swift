//
//  TravelPlanModelContainer.swift
//  Data
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core

public final class TravelPlanModelContainer: Sendable {

    // MARK: - Properties

    public static let shared = TravelPlanModelContainer()

    public let modelContainer: ModelContainer

    // MARK: - Init

    private init() {
        let schema = Schema([TravelPlanModel.self, TravelPlanDetailModel.self, TravelPlanDetailSpotModel.self])
        do {
            let configuration = ModelConfiguration("TravelPlan", schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            AppLogger.core.log(.error, "TravelPlanModelContainer 생성 실패, in-memory로 폴백: \(error.localizedDescription)")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            guard let fallback = try? ModelContainer(for: schema, configurations: fallbackConfig) else {
                fatalError("TravelPlanModelContainer in-memory 폴백조차 실패: \(error.localizedDescription)")
            }
            self.modelContainer = fallback
        }
    }
}
