//
//  TravelPlanShareUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 플랜을 JSON으로 내보내기/가져오기 하는 순수 로직 UseCase. Repository 의존성이 없어 Data 모듈 조립 없이 App에서 그대로 사용 가능하다
public final class TravelPlanShareUseCase: TravelPlanShareUseCaseProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func exportData(plan: TravelPlan, detail: TravelPlanDetail?) throws -> Data {
        let payload = SharePayload(plan: plan, spots: detail?.spots ?? [])
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(payload)
        } catch {
            throw TabiError.decodingFailed(message: error.localizedDescription)
        }
    }

    public func importPlan(from data: Data) throws -> (plan: TravelPlan, detail: TravelPlanDetail) {
        let payload: SharePayload
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            payload = try decoder.decode(SharePayload.self, from: data)
        } catch {
            throw TabiError.decodingFailed(message: error.localizedDescription)
        }

        // 받는 사람의 독립된 레코드로 취급하기 위해 새 UUID를 발급한다
        let newPlanId = UUID()
        let plan = TravelPlan(
            id: newPlanId,
            title: payload.plan.title,
            region: KoreanRegion(rawValue: payload.plan.region) ?? .etc,
            customRegionText: payload.plan.customRegionText,
            customEmoji: payload.plan.customEmoji,
            startDate: payload.plan.startDate,
            endDate: payload.plan.endDate
        )

        let spots = payload.spots.map { spotPayload in
            TravelPlanDetailSpot(
                id: UUID(),
                dayIndex: spotPayload.dayIndex,
                order: spotPayload.order,
                category: CategoryType(rawValue: spotPayload.category) ?? .sightseeing,
                title: spotPayload.title,
                subtitle: spotPayload.subtitle,
                startTime: spotPayload.startTime,
                durationMinutes: spotPayload.durationMinutes,
                contentId: spotPayload.contentId,
                coordinate: Coordinate(latitude: spotPayload.latitude, longitude: spotPayload.longitude),
                thumbnailURLString: spotPayload.thumbnailURLString,
                isCustom: spotPayload.isCustom,
                address: spotPayload.address
            )
        }

        return (plan, TravelPlanDetail(planId: newPlanId, spots: spots))
    }
}

// MARK: - SharePayload

/// Domain 엔티티를 직접 Codable로 만들지 않고, 공유 목적의 변환 전용 타입으로 인코딩/디코딩을 격리한다
private struct SharePayload: Codable {
    struct PlanPayload: Codable {
        let title: String
        let region: String
        let customRegionText: String?
        let customEmoji: String?
        let startDate: Date
        let endDate: Date
    }

    struct SpotPayload: Codable {
        let dayIndex: Int
        let order: Int
        let category: String
        let title: String
        let subtitle: String?
        let startTime: Date
        let durationMinutes: Int
        let contentId: String
        let latitude: Double
        let longitude: Double
        let thumbnailURLString: String?
        let isCustom: Bool
        let address: String?
    }

    let plan: PlanPayload
    let spots: [SpotPayload]

    init(plan: TravelPlan, spots: [TravelPlanDetailSpot]) {
        self.plan = PlanPayload(
            title: plan.title,
            region: plan.region.rawValue,
            customRegionText: plan.customRegionText,
            customEmoji: plan.customEmoji,
            startDate: plan.startDate,
            endDate: plan.endDate
        )
        self.spots = spots.map { spot in
            SpotPayload(
                dayIndex: spot.dayIndex,
                order: spot.order,
                category: spot.category.rawValue,
                title: spot.title,
                subtitle: spot.subtitle,
                startTime: spot.startTime,
                durationMinutes: spot.durationMinutes,
                contentId: spot.contentId,
                latitude: spot.coordinate.latitude,
                longitude: spot.coordinate.longitude,
                thumbnailURLString: spot.thumbnailURLString,
                isCustom: spot.isCustom,
                address: spot.address
            )
        }
    }
}
